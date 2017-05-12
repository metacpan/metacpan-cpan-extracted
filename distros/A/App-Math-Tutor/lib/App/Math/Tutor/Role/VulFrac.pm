package App::Math::Tutor::Role::VulFrac;

use warnings;
use strict;

=head1 NAME

App::Math::Tutor::Role::VulFrac - role for vulgar fraction numbers

=cut

use Moo::Role;
use App::Math::Tutor::Numbers;

our $VERSION = '0.005';

sub _check_vulgar_fraction
{
    $_[1]->num >= 2 and $_[1]->denum >= 2 and $_[1]->num % $_[1]->denum != 0;
}

requires "format";

sub _guess_vulgar_fraction
{
    my ( $max_num, $max_denum, $neg ) = ( @{ $_[0]->format }, $_[0]->negativable );
    my ( $num, $denum );
    ( $num, $denum ) =
      $neg
      ? ( int( rand( $max_num * 2 ) - $max_num ), int( rand( $max_denum * 2 ) - $max_denum ) )
      : ( int( rand($max_num) ), int( rand($max_denum) ) );
    VulFrac->new(
        num   => $num,
        denum => $denum
    );
}

=head1 METHODS

=head2 get_vulgar_fractions

Returns as many vulgar fractions as requested. Does Factory :)

=cut

sub get_vulgar_fractions
{
    my ( $self, $amount ) = @_;
    my @result;

    while ( $amount-- )
    {
        my $vf;
        do
        {
            $vf = $self->_guess_vulgar_fraction;
        } while ( !$self->_check_vulgar_fraction($vf) );

        push @result, $vf;
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
