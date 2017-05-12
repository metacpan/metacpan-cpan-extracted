package App::Math::Tutor::Role::Natural;

use warnings;
use strict;

=head1 NAME

App::Math::Tutor::Role::Natural - role for natural numbers

=cut

use Moo::Role;
use App::Math::Tutor::Numbers;

our $VERSION = '0.005';

sub _check_natural_number { $_[0]->value >= 2 }

requires "format";

sub _guess_natural_number
{
    my $max_val = $_[0]->format;
    my $value   = int( rand($max_val) );
    NatNum->new( value => $value );
}

=head1 METHODS

=head2 get_natural_number

Returns as many natural numbers as requested. Does Factory :)

=cut

sub get_natural_number
{
    my ( $self, $amount ) = @_;
    my @result;

    while ( $amount-- )
    {
        my $nn;
        do
        {
            $nn = $self->_guess_natural_number;
        } while ( !_check_natural_number($nn) );

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
