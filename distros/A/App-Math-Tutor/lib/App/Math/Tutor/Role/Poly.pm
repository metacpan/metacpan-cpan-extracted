package App::Math::Tutor::Role::Poly;

use warnings;
use strict;

=head1 NAME

App::Math::Tutor::Role::Poly - role for polynoms

=cut

use Moo::Role;
use App::Math::Tutor::Numbers;

our $VERSION = '0.005';

sub _check_polynom
{
    my $values = [ grep { $_->factor } @{ $_[1]->values } ];
    scalar @{$values} > 1
      and defined $values->[0]->exponent
      and $values->[0]->exponent == $_[0]->max_power
      and $values->[0]->exponent != 0;
}

requires "max_power", "format", "probability";

sub _guess_polynom
{
    my $probability = $_[0]->probability;
    my $max_val     = $_[0]->format;
    my @values;
    foreach my $exp ( 0 .. $_[0]->max_power )
    {
        rand(100) <= $probability or next;
        my $value = int( rand( $max_val * 2 ) - $max_val );
        push @values,
          PolyTerm->new(
            factor   => $value,
            exponent => $exp
          );
    }
    PolyNum->new(
        values   => [ reverse @values ],
        operator => "+"
    );
}

=head1 METHODS

=head2 get_polynom

Returns as many polynoms as requested. Does Factory :)

=cut

sub get_polynom
{
    my ( $self, $amount ) = @_;
    my @result;

    while ( $amount-- )
    {
        my $nn;
        do
        {
            $nn = $self->_guess_polynom;
        } while ( !$self->_check_polynom($nn) );

        push @result, $nn;
    }

    @result;
}

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
