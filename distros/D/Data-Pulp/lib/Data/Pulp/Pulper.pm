package Data::Pulp::Pulper;

use Moose;
use MooseX::AttributeHelpers;
use Data::Pulp::Carp;

sub parse {
    my $class = shift;

    my ( @rule, @case, $in_case, $empty_then, $nil_then, $default_then );
    while ( @_ ) {
        my $token = shift;
        if ( $token eq 'case' || $token eq 'if_type' || $token eq 'if_value' || $token eq 'if_object' ) {
            $in_case = 1;
            push @case, [ $token, shift ];
        }
        elsif ( $in_case ) {
            if ( $token eq 'then' ) {
                my $then = shift;
                push @rule, map { Data::Pulp::Rule->new( kind => $_->[0], matcher => $_->[1], then => $then ) } @case;
                $in_case = 0;
            }
            else {
                croak "Unrecognized token in case: $token";
            }
        }
        elsif ( $token eq 'empty' ) {
            $empty_then = shift;
        }
        elsif ( $token eq 'nil' ) {
            $nil_then = shift;
        }
        elsif ( $token eq 'default' ) {
            $default_then = shift;
        }
        elsif ( $token eq 'then' ) {
            croak "Then without opening case ($token)";
        }
        else {
            croak "Unrecognized token in case: $token";
        }
    }

    return __PACKAGE__->new( rule_list => \@rule, empty_then => $empty_then, nil_then => $nil_then, default_then => $default_then ); 
}

has [qw/ empty_then nil_then default_then /] => qw/is ro isa Maybe[CodeRef]/;
has rule_list => qw/metaclass Collection::Array reader _rule_list isa ArrayRef/, default => sub { [] }, provides => {qw/
    elements rule_list
/};

sub pulp {
    my $self = shift;
    my $value = shift;

    my $then;
    if ( defined $value ) {
        if ( ref $value || length $value ) {
            for my $rule ( $self->rule_list ) {
                if ( $rule->match( $value ) ) {
                    $then = $rule->then;
                    last;
                }
            }
        }
        elsif ( $then = $self->empty_then ) {
        }
    }
    elsif ( $then = $self->nil_then ) {
    }

    $then = $self->default_then unless $then;

    if ( $then ) {
        local $_ = $value;
        return $then->( $_ );
    }

    return $value; # Unmolested
}

sub prepare {
    my $self = shift;
    return Data::Pulp::Set->new( pulper => $self, source => shift );
}

sub set {
    return shift->prepare( @_ );
}

package Data::Pulp::Set;

use Moose;
use Data::Pulp::Carp;

use List::Enumerator qw/E/;

has pulper => qw/is ro required 1 isa Data::Pulp::Pulper/;
has source => qw/is ro/;
has _list => qw/is ro lazy_build 1/, handles => [qw/ is_empty /];
sub _build__list {
    my $self = shift;

    my $source = $self->source;
    my @list;
    if ( ref $source eq 'ARRAY' ) {
        my $count = 0;
        @list = map { [ $count++, $_ ] } @$source;
    }
    elsif ( ref $source eq 'HASH' ) {
        @list = map { [ $_, $source->{$_} ] } keys %$source;
    }
    else {
        @list = ( [ undef, $source ] );
    }

    return E \@list;
}

sub pulp_value {
    my $self = shift;
    my $value = shift;
    return $self->pulper->pulp( $value );
}

sub pulp_pair {
    my $self = shift;
    my $pair = shift;
    return $self->pulp_value( $pair->[1] );
}

sub all {
    my $self = shift;
    return $self->_list->map( sub { $self->pulp_pair( $_ ) } );
}

sub pulp {
    return shift->first( @_ );
}

sub get {
    return shift->first( @_ );
}

sub first {
    my $self = shift;
    return if $self->is_empty;
    return $self->pulp_pair( $self->_list->first );
}

sub last {
    my $self = shift;
    return if $self->is_empty;
    return $self->pulp_pair( $self->_list->last );
}

sub next {
    my $self = shift;
    return if $self->is_empty;
    my $pair;
    eval {
        $pair = $self->_list->next;
    };
    return unless $pair;
    return $self->pulp_pair( $pair );
}

package Data::Pulp::Rule;

use Moose;
use Data::Pulp::Carp;

has kind => qw/is ro required 1 isa Str/;
has matcher => qw/is ro required 1 isa Str|CodeRef|RegexpRef/;
has then => qw/is ro required 1 isa CodeRef/;

sub match {
    my $self = shift;
    my $value = shift;

    my $matcher = $self->matcher;
    my $kind = $self->kind;

    if ($kind eq 'case') {
    }
    elsif ($kind eq 'if_value') {
        return unless ! ref $value;
    }
    elsif ($kind eq 'if_type') {
        $value = ref $value;
    }
    elsif ($kind eq 'if_object') {
        return unless blessed $value;
    }
    else {
        croak "Don't know how to match kind \"$kind\"";
    }

    if ( ref $matcher eq 'CODE' ) {
        local $_ = $value;
        return $matcher->( $value );
    }
    elsif ( ref $matcher eq 'Regexp' ) { # Meh, not really used
        return $value =~ $matcher;
    }
    elsif ( ! ref $matcher ) { # Meh, not really used
        return $value eq $matcher;
    }
    else {
        croak "Don't understand matcher \"$matcher\"";
    }
}

sub run {
    my $self = shift;
    my $value = shift;
    
    {
        local $_ = $value;
        return $self->then->( $value );
    }
}

1;
