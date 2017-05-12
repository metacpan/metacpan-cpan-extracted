package App::Math::Tutor::Role::DecFrac;

use warnings;
use strict;

=head1 NAME

App::Math::Tutor::Role::DecFrac - role for decimal fraction numbers

=cut

use Moo::Role;
use App::Math::Tutor::Numbers;

our $VERSION = '0.005';

requires "range", "digits";

sub _check_decimal_fraction
{
    my $self = shift;
    my ( $minr, $minc, $maxr, $maxc ) = @{ $self->range };
    my $digits = $self->digits;
    $digits += length( "" . int( $_[0] ) ) + 1;
    my $s1 = sprintf( "%.${digits}g", $_[0] );

    $minc->( $minr, $_[0] ) and $maxc->( $maxr, $_[0] ) and $s1 == $_[0] and length($s1) >= 3;
}

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
