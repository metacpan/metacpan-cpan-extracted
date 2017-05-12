package Chart::Sequence::Object;

$VERSION = 0.000_1;

=head1 NAME

Chart::Sequence::Object - A base class with utility functions for all Chart::Sequence objects

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

=for test_script t/Chart-Sequence.t

=cut

use strict;
use Carp;

=head1 METHODS

=over

=item new

=cut

use vars qw( %_initted_members );
sub new {
    my $class = ref $_[0] ? ref shift : shift;

    if ( @_ == 1 ) {
        if ( ref $_[0] eq "HASH" ) {
            @_ = %{$_[0]};
        }
    }

    my $self = bless {}, $class;
    local %_initted_members;
    while ( @_ ) {
        my ( $key, $value ) = ( shift, shift );
        ( my $method_name = $key ) =~ s/^([A-Z])/\l$1/;
        $method_name =~ s/([A-Z])/_\l$1/g;
        my $method = $self->can( "_init_$method_name" );
        if ( $method ) {
            $method_name = "_init_$method_name";
        }
        else {
            $method = $self->can( $method_name );
        }
        croak "Can't find method '$method_name' in $class" unless $method;
        $self->$method( $value );
        $_initted_members{ $method_name }++;
    }
    $self->_init_members( ref $self );
    return $self;
}


__PACKAGE__->make_methods(qw( $name ));

sub _init_members {
    my $self = shift;
    my ( $class ) = @_;

    no strict "refs";
    for ( @{"${class}::ISA"} ) {
        my $s = $_->can( "_init_members" );
        $self->$s( $_ )
            if $s;
    }

    for ( @{"${class}::_member_initers"} ) {
        next if $_initted_members{$_}++;
        $self->$_();
    }
}

=item name

Sets/gets the name of an object.

=cut

=item make_methods

Builds accessor methods for the indicated data elements:

    __PACKAGE__->make_methods( qw(
        $name
        @messages
    ) );

=cut

sub make_methods {
    my $class = shift;
    my @code;

    while ( @_ ) {
        local $_ = shift;
        my $options = @_ && ref $_[0] ? shift : {};

        s/^([\$\@])//;
        my $type = $1 || "\$";
        ( my $n = $_ ) =~ s{(?:^|_)(\w)}{\u$1}g;

        my $set_pre = defined $options->{set_pre} ? $options->{set_pre} : "";
        my $get_pre = defined $options->{get_pre} ? $options->{get_pre} : "";

        push @code, <<END_MAP;
\$${class}::_member_types{$_} = '$type';
END_MAP

        if ( $type eq "\$" ) {
            push @code, <<END_SUB;
#line 1 ${class}::$_, compiled by Class::Sequence::Base::make_methods
sub $_ {
    my \$self = shift;
    Carp::croak "Too many parameters passed" if \@_ > 1;
    if ( \@_ ) {
        local \$_ = shift;
        $set_pre
        \$self->{$n} = \$_;
    }
    $get_pre
    return \$self->{$n};
}
END_SUB
        }
        elsif ( $type eq "\@" ) {
            push @code, <<END_SUB;
#line 1 ${class}::_init_$_, compiled by Class::Sequence::Base::make_methods
sub _init_$_ {
    my \$self = shift;
    \$self->{$n} = [];
    map \$self->push_$_( \$_ ), \@{shift()} if \@_;
}
push \@${class}::_member_initers, "_init_$_";

#line 1 ${class}::$_, compiled by Class::Sequence::Base::make_methods
sub $_ {
    my \$self = shift;
    if ( \@_ ) {
        \$self->_init_$_;
        \$self->push_$_( \@_ );
    }
    $get_pre
    return \@{\$self->{$n}};
}

#line 1 ${class}::${_}_ref, compiled by Class::Sequence::Base::make_methods
sub ${_}_ref {
    my \$self = shift;
    Carp::croak "Too many parameters passed" if \@_ > 1;
    if ( \@_ ) {
        \$self->_init_$_;
        \$self->push_$_( \@{\$_[1]} );
    }
    $get_pre
    return \$self->{$n};
}

#line 1 ${class}::push_$_, compiled by Class::Sequence::Base::make_methods
sub push_$_ {
    my \$self = shift;
    while ( \@_ ) {
        local \$_ = shift;
        $set_pre
        push \@{\$self->{$n}}, \$_;
    }
}
END_SUB
        }
        else {
            croak "Unrecognized accessor type: '$type'";
        }
    }
    eval join "", "package ", $class, ";\n", @code, 1 or die $@, @code;
}

=back

=head1 LIMITATIONS

=head1 COPYRIGHT

    Copyright 2002, R. Barrie Slaymaker, Jr., All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, oir GPL licenses,
any version.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1;
