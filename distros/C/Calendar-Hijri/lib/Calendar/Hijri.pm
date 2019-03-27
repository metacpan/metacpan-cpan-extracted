package Calendar::Hijri;

=head1 NAME

Calendar::Hijri - Interface to Islamic Calendar.

=head1 VERSION

Version 0.36

=cut

use 5.006;
use Data::Dumper;

use Date::Hijri::Simple;
use Moo;
use namespace::autoclean;
with 'Calendar::Plugin::Renderer';

use overload q{""} => 'as_string', fallback => 1;

$Calendar::Hijri::VERSION   = '0.36';
$Calendar::Hijri::AUTHORITY = 'cpan:MANWAR';

has year  => (is => 'rw', predicate => 1);
has month => (is => 'rw', predicate => 1);
has date  => (is => 'ro', default   => sub { Date::Hijri::Simple->new });

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

Hijri Calendar begins with the migration from Mecca to Medina of Mohammad (pbuh),
the Prophet of Islam, an event  known  as the Hegira. The initials A.H.  before a
date mean "anno Hegirae" or "after Hegira". The  first  day  of the year is fixed
in the Quran as the first day of the month of Muharram.In 17 AH Umar I,the second
caliph, established the beginning of the era of the Hegira ( 1 Muharram 1 AH ) as
the date that is 16 July 622 CE in the Julian Calendar.

The years are lunar & consist of 12 lunar months. There is no intercalary period,
since the Quran ( Sura IX, verses 36,37 )  sets  the calendar year  at 12 months.
Because the year in the Hijri  calendar is shorter than a solar year, the  months
drift with respect to the seasons, in a cycle 32.50 years.

    +--------------------------------------------------------------------------------------------------------+
    |                                       Sha'aban        [1436 BE]                                        |
    +--------------+--------------+--------------+--------------+--------------+--------------+--------------+
    |      al-Ahad |   al-Ithnayn | ath-Thulatha |     al-Arbia |    al-Khamis |    al-Jumuah |      as-Sabt |
    +--------------+--------------+--------------+--------------+--------------+--------------+--------------+
    |                                            |            1 |            2 |            3 |            4 |
    +--------------+--------------+--------------+--------------+--------------+--------------+--------------+
    |            5 |            6 |            7 |            8 |            9 |           10 |           11 |
    +--------------+--------------+--------------+--------------+--------------+--------------+--------------+
    |           12 |           13 |           14 |           15 |           16 |           17 |           18 |
    +--------------+--------------+--------------+--------------+--------------+--------------+--------------+
    |           19 |           20 |           21 |           22 |           23 |           24 |           25 |
    +--------------+--------------+--------------+--------------+--------------+--------------+--------------+
    |           26 |           27 |           28 |           29 |                                            |
    +--------------+--------------+--------------+--------------+--------------+--------------+--------------+

The package L<App::calendr> provides command line tool  C<calendr> to display the
supported calendars on the terminal.

=head1 SYNOPSIS

    use strict; use warnings;
    use Calendar::Hijri;

    # prints current hijri month calendar.
    print Calendar::Hijri->new, "\n";
    print Calendar::Hijri->new->current, "\n";

    # prints hijri month calendar for the first month of year 1436.
    print Calendar::Hijri->new({ month => 1, year => 1436 }), "\n";

    # prints hijri month calendar in which the given gregorian date falls in.
    print Calendar::Hijri->new->from_gregorian(2015, 1, 14), "\n";

    # prints hijri month calendar in which the given julian date falls in.
    print Calendar::Hijri->new->from_julian(2457102.5), "\n";

    # prints current month hijri calendar in SVG format.
    print Calendar::Hijri->new->as_svg;

    # prints current month hijri calendar in text format.
    print Calendar::Hijri->new->as_text;

=head1 HIJRI MONTHS

    +--------+------------------------------------------------------------------+
    | Number | Name                                                             |
    +--------+------------------------------------------------------------------+
    |   1    | Muharram                                                         |
    |   2    | Safar                                                            |
    |   3    | Rabi' al-awwal                                                   |
    |   4    | Rabi' al-thani                                                   |
    |   5    | Jumada al-awwal                                                  |
    |   6    | Jumada al-thani                                                  |
    |   7    | Rajab                                                            |
    |   8    | Sha'aban                                                         |
    |   9    | Ramadan                                                          |
    |  10    | Shawwal                                                          |
    |  11    | Dhu al-Qi'dah                                                    |
    |  12    | Dhu al-Hijjah                                                    |
    +--------+------------------------------------------------------------------+

=head1 HIJRI DAYS

    +--------------+------------------------------------------------------------+
    | Arabic Name  | English Name                                               |
    +--------------+------------------------------------------------------------+
    |      al-Ahad | Sunday                                                     |
    |   al-Ithnayn | Monday                                                     |
    | ath-Thulatha | Tuesday                                                    |
    |     al-Arbia | Wednesday                                                  |
    |    al-Khamis | Thursday                                                   |
    |    al-Jumuah | Friday                                                     |
    |      as-Sabt | Saturday                                                   |
    +--------------+------------------------------------------------------------+

=head1 METHODS

=head2 current()

Returns current month of the Hijri calendar.

=cut

sub current {
    my ($self) = @_;

    return $self->as_text($self->date->month, $self->date->year);
}

=head2 from_gregorian()

Returns Hijri month calendar in which the given gregorian date falls in.

=cut

sub from_gregorian {
    my ($self, $year, $month, $day) = @_;

    return $self->from_julian($self->date->gregorian_to_julian($year, $month, $day));
}

=head2 from_julian($julian_date)

Returns Hijri month calendar in which the given julian date falls in.

=cut

sub from_julian {
    my ($self, $julian) = @_;

    my $date = $self->date->from_julian($julian);
    return $self->as_text($date->month, $date->year);
}

=head2 as_text($month, $year)

Returns  color  coded  Hijri  calendar  for  the given C<$month> and C<$year>. If
C<$month> and C<$year> missing, it would return current calendar month.

=cut

sub as_text {
    my ($self, $month, $year) = @_;

    ($month, $year) = $self->validate_params($month, $year);
    my $date = Date::Hijri::Simple->new({ year => $year, month => $month, day => 1 });

    return $self->text_calendar(
        {
            start_index => $date->day_of_week,
            month_name  => $date->get_month_name,
            days        => $date->days_in_month_year($month, $year),
            year        => $year,
            day_names   => $date->days,
        });
}

=head2 as_svg($month, $year)

Returns calendar for the given C<$month> and C<$year> rendered  in SVG format. If
C<$month> and C<$year> missing, it would return current calendar month.

=cut

sub as_svg {
    my ($self, $month, $year) = @_;

    ($month, $year) = $self->validate_params($month, $year);
    my $date = Date::Hijri::Simple->new({ year => $year, month => $month, day => 1 });

    return $self->svg_calendar({
        start_index => $date->day_of_week,
        month_name  => $date->get_month_name,
        days        => $date->days_in_month_year($month, $year),
        year        => $year });
}

sub as_string {
    my ($self) = @_;

    return $self->as_text($self->month, $self->year);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Calendar-Hijri>

=head1 SEE ALSO

=over 4

=item L<Calendar::Bahai>

=item L<Calendar::Gregorian>

=item L<Calendar::Persian>

=item L<Calendar::Saka>

=back

=head1 BUGS

Please report any bugs / feature requests to C<bug-calendar-hijri at rt.cpan.org>
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Calendar-Hijri>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Calendar::Hijri

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Calendar-Hijri>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Calendar-Hijri>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Calendar-Hijri>

=item * Search CPAN

L<http://search.cpan.org/dist/Calendar-Hijri/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2016 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain  a copy of the full
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

1; # End of Calendar::Hijri
