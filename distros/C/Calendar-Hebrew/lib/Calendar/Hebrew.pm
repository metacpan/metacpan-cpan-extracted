package Calendar::Hebrew;

$Calendar::Hebrew::VERSION   = '0.12';
$Calendar::Hebrew::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Calendar::Hebrew - Interface to Hebrew Calendar.

=head1 VERSION

Version 0.12

=cut

use 5.006;
use Data::Dumper;

use Date::Hebrew::Simple;
use Moo;
use namespace::autoclean;
with 'Calendar::Plugin::Renderer';

use overload q{""} => 'as_string', fallback => 1;

has year  => (is => 'rw', predicate => 1);
has month => (is => 'rw', predicate => 1);
has date  => (is => 'ro', default   => sub { Date::Hebrew::Simple->new });

sub BUILD {
    my ($self) = @_;

    $self->date->validate_year($self->year) if $self->has_year;
    $self->date->validate_hebrew_month($self->month, $self->year) if $self->has_month;

    unless ($self->has_year && $self->has_month) {
        $self->year($self->date->year);
        $self->month($self->date->month);
    }
}

=head1 DESCRIPTION

The C<Calendar::Hebrew> was released on Sunday 23rd July 2017 to mark the completion
of L<1000th consecutive days of releasing to CPAN|http://blogs.perl.org/users/mohammad_s_anwar/2017/07/1000th-consecutive-days-releasing-to-cpan.html>.

The Hebrew or Jewish calendar is a lunisolar  calendar  used  today predominantly
for Jewish religious observances. It determines the dates for Jewish holidays and
the appropriate public reading of Torah portions, yahrzeits (dates to commemorate
the death of a relative), and daily Psalm readings, among many ceremonial uses.

The Hebrew lunar year is  about  eleven days shorter than the solar year and uses
the  19-year  Metonic  cycle  to bring it into line with the solar year, with the
addition  of an  intercalary month every two or three years, for a total of seven
 times  per  19 years. Even  with this intercalation, the average Hebrew calendar
year  is  longer by about 6 minutes and 40 seconds than the current mean tropical
year, so  that  every  216  years  the Hebrew calendar will fall a day behind the
current  mean  tropical year; and about every 231 years it will fall a day behind
the mean Gregorian calendar year.

    +--------------------------------------------------------------------------------------------------------+
    |                                            Tammuz [5777 BE]                                            |
    +--------------+--------------+--------------+--------------+--------------+--------------+--------------+
    |   Yom Rishon |    Yom Sheni | Yom Shelishi |    Yom Revil |  Yom Hamishi |   Yom Shishi |      Shabbat |
    +--------------+--------------+--------------+--------------+--------------+--------------+--------------+
    |            1 |            2 |            3 |            4 |            5 |            6 |            7 |
    +--------------+--------------+--------------+--------------+--------------+--------------+--------------+
    |            8 |            9 |           10 |           11 |           12 |           13 |           14 |
    +--------------+--------------+--------------+--------------+--------------+--------------+--------------+
    |           15 |           16 |           17 |           18 |           19 |           20 |           21 |
    +--------------+--------------+--------------+--------------+--------------+--------------+--------------+
    |           22 |           23 |           24 |           25 |           26 |           27 |           28 |
    +--------------+--------------+--------------+--------------+--------------+--------------+--------------+
    |           29 |                                                                                         |
    +--------------+--------------+--------------+--------------+--------------+--------------+--------------+

The package L<App::calendr> provides command line tool  C<calendr> to display the
supported calendars on the terminal. Support for  C<Hebrew Calendar>  is provided
by L<App::calendr> v0.16 or above.

=head1 SYNOPSIS

    use strict; use warnings;
    use Calendar::Hebrew;

    # prints current month calendar
    print Calendar::Hebrew->new, "\n";
    print Calendar::Hebrew->new->current, "\n";

    # prints hebrew month calendar in which the given gregorian date falls in.
    print Calendar::Hebrew->new->from_gregorian(2015, 1, 14), "\n";

    # prints hebrew month calendar in which the given julian day falls in.
    print Calendar::Hebrew->new->from_julian(2457102.5), "\n";

    # prints current month hebrew calendar in SVG format.
    print Calendar::Hebrew->new->as_svg;

    # prints current month hebrewn calendar in text format.
    print Calendar::Hebrew->new->as_text;

=head1 HEBREW MONTHS

    +-------+-------------------------------------------------------------------+
    | Month | Hebrew Name                                                       |
    +-------+-------------------------------------------------------------------+
    |     1 | Nisan                                                             |
    |     2 | Iyar                                                              |
    |     3 | Sivan                                                             |
    |     4 | Tammuz                                                            |
    |     5 | Av                                                                |
    |     6 | Elul                                                              |
    |     7 | Tishrei                                                           |
    |     8 | Cheshvan                                                          |
    |     9 | Kislev                                                            |
    |    10 | Tevet                                                             |
    |    11 | Shevat                                                            |
    |    12 | Adar                                                              |
    +-------+-------------------------------------------------------------------+

In leap years (such as 5774) an additional month, Adar I (30 days) is added after
Shevat, while the regular Adar is referred to as "Adar II."

=head1 HEBREW DAYS

    +-------+---------------+---------------------------------------------------+
    | Index | Hebrew Name   | English Name                                      |
    +-------+---------------+---------------------------------------------------+
    |     0 | Yom Rishon    | Sunday                                            |
    |     1 | Yom Sheni     | Monday                                            |
    |     2 | Yom Shelishi  | Tuesday                                           |
    |     3 | Yom Revil     | Wednesday                                         |
    |     4 | Yom Hamishi   | Thursday                                          |
    |     5 | Yom Shishi    | Friday                                            |
    |     6 | Shabbat       | Saturday                                          |
    +-------+---------------+---------------------------------------------------+


=head1 CONSTRUCTOR

It expects month and year optionally. By default it gets current Hebrew month and
year.

=head1 METHODS

=head2 current()

Returns current month of the Hebrew calendar.

=cut

sub current {
    my ($self) = @_;

    return $self->as_text($self->date->month, $self->date->year);
}

=head2 from_gregorian($year, $month, $day)

Returns hebrew month calendar in which the given gregorian date falls in.

=cut

sub from_gregorian {
    my ($self, $year, $month, $day) = @_;

    return $self->from_julian($self->date->gregorian_to_julian($year, $month, $day));
}

=head2 from_julian($julian_day)

Returns hebrew month calendar in which the given julian day falls in.

=cut

sub from_julian {
    my ($self, $julian_day) = @_;

    my $date = $self->date->from_julian($julian_day);
    return $self->as_text($date->month, $date->year);
}

=head2 as_svg($month, $year)

Returns calendar for the given C<$month> and C<$year> rendered  in SVG format. If
C<$month> and C<$year> missing, it would return current calendar month.

=cut

sub as_svg {
    my ($self, $month, $year) = @_;

    ($month, $year) = $self->validate_params($month, $year);
    my $date = Date::Hebrew::Simple->new({ year => $year, month => $month, day => 1 });

    return $self->svg_calendar({
        start_index => $date->day_of_week,
        month_name  => $date->get_month_name,
        days        => $date->days_in_month_year($month, $year),
        year        => $year });
}

=head2 as_text($month, $year)

Returns  color  coded   Hebrew  calendar for the given C<$month> and C<$year>. If
C<$month> and C<$year> missing, it would return current calendar month.

=cut

sub as_text {
    my ($self, $month, $year) = @_;

    ($month, $year) = $self->validate_params($month, $year);
    my $date = Date::Hebrew::Simple->new({ year => $year, month => $month, day => 1 });

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

#
#
# Override validate_params()
sub validate_params {
    my ($self, $month, $year) = @_;

    $month = $self->month unless defined $month;
    $year  = $self->year  unless defined $year;

    $self->date->validate_year($year);
    $self->date->validate_hebrew_month($month, $year);

    return ($month, $year);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Calendar-Hebrew>

=head1 ACKNOWLEDGEMENTS

The C<Calendar::Hebrew> namespace was originally owned by Yitzchak Scott-Thoennes.
Yitzchak has kindly transferred the ownership to me, so that I can keep working on
it.

=head1 SEE ALSO

=over 4

=item L<Calendar::Bahai>

=item L<Calendar::Hijri>

=item L<Calendar::Gregorian>

=item L<Calendar::Persian>

=item L<Calendar::Saka>

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-calendar-hebrew at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Calendar-Hebrew>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Calendar::Hebrew

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Calendar-Hebrew>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Calendar-Hebrew>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Calendar-Hebrew>

=item * Search CPAN

L<http://search.cpan.org/dist/Calendar-Hebrew/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017 Mohammad S Anwar.

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

1; # End of Calendar::Hebrew
