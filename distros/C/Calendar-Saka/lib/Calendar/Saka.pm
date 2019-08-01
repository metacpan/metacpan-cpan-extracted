package Calendar::Saka;

$Calendar::Saka::VERSION   = '1.41';
$Calendar::Saka::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Calendar::Saka - Interface to Indian Calendar.

=head1 VERSION

Version 1.41

=cut

use 5.006;
use Data::Dumper;

use Date::Saka::Simple;
use Moo;
use namespace::autoclean;
with 'Calendar::Plugin::Renderer';

use overload q{""} => 'as_string', fallback => 1;

has year  => (is => 'rw', predicate => 1);
has month => (is => 'rw', predicate => 1);
has date  => (is => 'ro', default   => sub { Date::Saka::Simple->new });

sub BUILD {
    my ($self) = @_;

    $self->date->validate_year($self->year)   if $self->has_year;
    $self->date->validate_month($self->month) if $self->has_month;

    unless ($self->has_year && $self->has_month) {
        $self->year($self->date->year);
        $self->month($self->date->month);
    }
}

=head1 DESCRIPTION

Module  to  play  with Saka calendar  mostly  used  in  the South indian, Goa and
Maharashatra. It supports the functionality to add / minus days, months and years
to a Saka date. It can also converts Saka date to Gregorian/Julian date.

The  Saka eras are lunisolar calendars, and feature annual cycles of twelve lunar
months, each month divided into two phases:   the  'bright half' (shukla) and the
'dark half'  (krishna);  these correspond  respectively  to  the  periods  of the
'waxing' and the 'waning' of the moon. Thus, the  period beginning from the first
day  after  the new moon  and  ending on the full moon day constitutes the shukla
paksha or 'bright half' of the month the period beginning from the  day after the
full moon until &  including the next new moon day constitutes the krishna paksha
or 'dark half' of the month.

The  "year zero"  corresponds  to  78 BCE in the Saka calendar. The Saka calendar
begins with the month of Chaitra (March) and the Ugadi/Gudi Padwa festivals  mark
the new year.

Each  month  in  the Shalivahana  calendar  begins with the  'bright half' and is
followed by the 'dark half'.  Thus,  each  month of the Shalivahana calendar ends
with the no-moon day and the new month begins on the day after that.

A variant of the Saka Calendar was reformed & standardized as the Indian National
calendar in 1957. This official  calendar follows the Shalivahan Shak calendar in
beginning from the month of Chaitra and counting years with 78 CE being year zero.
It features a constant number of days in every month with leap years.Saka Calendar
for the month of Chaitra year 1937

    +----------------------------------------------------------------------------------------------------------------------+
    |                                                 Chaitra    [1937 BE]                                                 |
    +----------------+----------------+----------------+----------------+----------------+----------------+----------------+
    |       Ravivara |        Somvara |    Mangalavara |      Budhavara | Brahaspativara |      Sukravara |       Sanivara |
    +----------------+----------------+----------------+----------------+----------------+----------------+----------------+
    |              1 |              2 |              3 |              4 |              5 |              6 |              7 |
    +----------------+----------------+----------------+----------------+----------------+----------------+----------------+
    |              8 |              9 |             10 |             11 |             12 |             13 |             14 |
    +----------------+----------------+----------------+----------------+----------------+----------------+----------------+
    |             15 |             16 |             17 |             18 |             19 |             20 |             21 |
    +----------------+----------------+----------------+----------------+----------------+----------------+----------------+
    |             22 |             23 |             24 |             25 |             26 |             27 |             28 |
    +----------------+----------------+----------------+----------------+----------------+----------------+----------------+
    |             29 |             30 |                                                                                    |
    +----------------+----------------+----------------+----------------+----------------+----------------+----------------+

The package L<App::calendr> provides command line tool  C<calendr> to display the
supported calendars on the terminal.

=head1 SYNOPSIS

    use strict; use warnings;
    use Calendar::Saka;

    # prints current saka month calendar.
    print Calendar::Saka->new->current, "\n";

    # prints saka month calendar in which the given gregorian date falls in.
    print Calendar::Saka->new->from_gregorian(2015, 4, 19), "\n";

    # prints saka month calendar in which the given julian date falls in.
    print Calendar::Saka->new->from_julian(2457102.5), "\n";

    # prints current month saka calendar in SVG format.
    print Calendar::Saka->new->as_svg;

    # prints current month saka calendar in text format.
    print Calendar::Saka->new->as_text;

=head1 SAKA MONTHS

    +-------+-------------------------------------------------------------------+
    | Order | Name                                                              |
    +-------+-------------------------------------------------------------------+
    |   1   | Chaitra                                                           |
    |   2   | Vaisakha                                                          |
    |   3   | Jyaistha                                                          |
    |   4   | Asadha                                                            |
    |   5   | Sravana                                                           |
    |   6   | Bhadra                                                            |
    |   7   | Asvina                                                            |
    |   8   | Kartika                                                           |
    |   9   | Agrahayana                                                        |
    |  10   | Pausa                                                             |
    |  11   | Magha                                                             |
    |  12   | Phalguna                                                          |
    +-------+-------------------------------------------------------------------+

=head1 SAKA DAYS

    +---------+-----------+-----------------------------------------------------+
    | Weekday | Gregorian | Saka                                                |
    +---------+-----------+-----------------------------------------------------+
    |    0    | Sunday    | Ravivara                                            |
    |    1    | Monday    | Somvara                                             |
    |    2    | Tuesday   | Mangalavara                                         |
    |    3    | Wednesday | Budhavara                                           |
    |    4    | Thursday  | Brahaspativara                                      |
    |    5    | Friday    | Sukravara                                           |
    |    6    | Saturday  | Sanivara                                            |
    +---------+-----------+-----------------------------------------------------+

=head1 METHODS

=head2 current()

Returns current month of the Saka calendar.

=cut

sub current {
    my ($self) = @_;

    return $self->as_text($self->date->month, $self->date->year);
}

=head2 from_gregorian()

Returns saka month calendar in which the given gregorian date falls in.

=cut

sub from_gregorian {
    my ($self, $year, $month, $day) = @_;

    return $self->from_julian($self->date->gregorian_to_julian($year, $month, $day));
}

=head2 from_julian($julian_date)

Returns saka month calendar in which the given julian date falls in.

=cut

sub from_julian {
    my ($self, $julian) = @_;

    my $date = $self->from_julian($julian);
    return $self->as_text($date->month, $date->year);
}

=head2 as_svg($month, $year)

Returns calendar for the given C<$month> and C<$year> rendered  in SVG format. If
C<$month> and C<$year> missing, it would return current calendar month.

=cut

sub as_svg {
    my ($self, $month, $year) = @_;

    ($month, $year) = $self->validate_params($month, $year);
    my $date = Date::Saka::Simple->new({ year => $year, month => $month, day => 1 });

    return $self->svg_calendar(
        {
            start_index => $date->day_of_week,
            month_name  => $date->get_month_name,
            days        => $date->days_in_month_year($month, $year),
            year        => $year
        });
}

=head2 as_text($month, $year)

Returns  color  coded  Saka  calendar  for  the  given C<$month> and C<$year>. If
C<$month> and C<$year> missing, it would return current calendar month.

=cut

sub as_text {
    my ($self, $month, $year) = @_;

    ($month, $year) = $self->validate_params($month, $year);
    my $date = Date::Saka::Simple->new({ year => $year, month => $month, day => 1 });

    return $self->text_calendar(
        {
            start_index => $date->day_of_week,
            month_name  => $date->get_month_name,
            days        => $date->days_in_month_year($month, $year),
            day_names   => $date->days,
            year        => $year
        });
}

sub as_string {
    my ($self) = @_;

    return $self->as_text($self->month, $self->year);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Calendar-Saka>

=head1 BUGS

Please  report any bugs or feature requests to C<bug-calendar-saka at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Calendar-Saka>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Calendar::Saka

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Calendar-Saka>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Calendar-Saka>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Calendar-Saka>

=item * Search CPAN

L<http://search.cpan.org/dist/Calendar-Saka/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2016 Mohammad S Anwar.

This  program  is  free software; you can redistribute it and/or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Calendar::Saka
