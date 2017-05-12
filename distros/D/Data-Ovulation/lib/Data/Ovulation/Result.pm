package Data::Ovulation::Result;

use strict;
use warnings;

use 5.008;

use Carp;
use base 'Class::Accessor';

__PACKAGE__->mk_accessors( qw/ day_rise cover_temperature impregnation ovulation_days fertile_days min max / );

=head1 NAME

Data::Ovulation::Result - Result class for Data::Ovulation

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

See L<Data::Ovulation>.

=head1 DESCRIPTION

See L<Data::Ovulation>.

=head1 SUBROUTINES/METHODS

=head2 C<day_rise()>

Returns the first day on which the temperature rises. This indicates an ovulation.

=head2 C<ovulation_days()>

Returns an arrayref of days on which an ovulation is likely to have occured.

=head2 C<fertile_days()>

Returns an arrayref of days with high fertility.

=head2 C<cover_temperature()>

Returns the "cover" temperature. This is the highest one of the six temperature
values prior to the ovulation day.

=head2 C<impregnation()>

Returns true if an impregnation is likely to have occured.

=head2 C<min()>

Returns the lowest temperature value.

=head2 C<max()>

Returns the highest temperature value.

=head1 AUTHOR

Tobias Kremer, C<< <cpan at funkreich.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Tobias Kremer, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
