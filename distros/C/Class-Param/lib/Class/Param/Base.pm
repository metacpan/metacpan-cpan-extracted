package Class::Param::Base;

use strict;
use warnings;

use Carp qw[];

BEGIN {

    my @abstract = qw[ new get set names remove ];

    foreach my $abstract ( @abstract ) {

        no strict 'refs';

        *$abstract = sub {
             my $class = ref $_[0] ? ref shift : shift;
             Carp::croak qq/Abstract method '$abstract' must be implemented in '$class'./;
        };
    }
}

sub add {
    my ( $self, $name, @add ) = @_;

    unless ( $self->has($name) ) {

        my $value;

        if ( @add == 1 ) {
            $value = ref $add[0] eq 'ARRAY' ? [ $add[0] ] : $add[0];
        }
        else {
            $value = \@add;
        }

        return $self->set( $name => $value );
    }

    my $value = $self->get($name);

    unless ( ref $value eq 'ARRAY' ) {
        $value = [ $value ];
    }

    push @{ $value }, @add;

    return $self->set( $name => $value );
}

sub has {
    my ( $self, $name ) = @_;

    foreach ( $self->names ) {
        return 1 if $_ eq $name;
    }

    return 0;
}

sub clear {
    my $self = shift;

    foreach ( $self->names ) {
        $self->remove($_);
    }

    return 1;
}

sub count {
    return scalar shift->names;
}

sub param {
    my ( $self, $name, @values ) = @_;

    if ( @_ == 1 ) {
        return $self->names;
    }

    unless ( defined $name ) {
        return wantarray ? () : undef;
    }

    if ( @_ == 2 ) {

        unless ( $self->has($name) ) {
            return wantarray ? () : undef;
        }

        my $value = $self->get($name);

        if ( ref $value eq 'ARRAY' ) {
            return wantarray ? @{ $value } : $value->[0];
        }
        else {
            return wantarray ? ( $value ) : $value;
        }
    }

    if ( @values == 1 && ! defined $values[0] ) {
        return $self->remove($name);
    }

    return $self->set( $name => @values > 1 ? \@values : $values[0] );
}

sub scan {
    my ( $self, $callback ) = @_;

    foreach ( $self->names ) {
        &$callback( $_, $self->param($_) );
    }

    return 1;
}

sub as_hash {
    my $self = shift;
    my %hash = ();

    $self->scan( sub {
        $hash{ shift() } = @_ > 2 ? \@_ : $_[1];
    });

    return wantarray ? %hash : \%hash;
}

1;

__END__

=head1 NAME

Class::Param::Base - Abstract class for param implementations

=head1 SYNOPSIS

    package MyParam;
    use base 'Class::Param::Base';

    sub get    { }
    sub set    { }
    sub names  { }
    sub remove { }

    1;

=head1 DESCRIPTION

Abstract class for param implementations

=head1 METHODS

=over 4

=item param

    # get
    @names   = $param->param;
    $value   = $param->param($name);
    @values  = $param->param($name);

    # set
    $param->param( $name => $value   );
    $param->param( $name => @values  );

    # remove
    $param->param( $name => undef    );

=item add

    $param->add( $name => $value );
    $param->add( $name => @values );

=item has

    $boolean = $param->has($name);

=item clear

    $param->clear;

=item count

    $count = $param->count;

=item scan

    $param->scan( sub {
        my ( $name, @values ) = @_;
    });

=item as_hash

    %hash = $param->as_hash;
    $hash = $param->as_hash;

=back

=head1 SUBCLASS

Subclasses must implement the following methods.

=over 4

=item new

=item get

    $value = $param->get($name);

=item set

    $param->set( $name => $value );

=item names

    @names = $param->names;

=item remove

    $removed = $param->remove($name);

=back

=head1 SEE ASLO

L<Class::Param>.

=head1 AUTHOR

Christian Hansen C<chansen@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
