package Date::Hebrew::Simple;

$Date::Hebrew::Simple::VERSION   = '0.13';
$Date::Hebrew::Simple::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Date::Hebrew::Simple - Represents Hebrew date.

=head1 VERSION

Version 0.13

=cut

use 5.006;
use Data::Dumper;
use Time::localtime;
use POSIX qw/floor ceil/;
use Date::Calc qw/Delta_Days/;
use Date::Exception::InvalidMonth;

use Moo;
use namespace::autoclean;

use overload q{""} => 'as_string', fallback => 1;

=head1 DESCRIPTION

Represents the Hebrew date.

=cut

our $HEBREW_MONTHS = [
    '',
    'Nisan',   'Iyar',     'Sivan',  'Tammuz', 'Av',     'Elul',
    'Tishrei', 'Cheshvan', 'Kislev', 'Tevet',  'Shevat', 'Adar',
];

our $HEBREW_DAYS = [
    'Yom Rishon',  'Yom Sheni',  'Yom Shelishi', 'Yom Revil',
    'Yom Hamishi', 'Yom Shishi', 'Shabbat',
];

has hebrew_epoch => (is => 'ro', default => sub { 347995.5       });
has days         => (is => 'ro', default => sub { $HEBREW_DAYS   });
has months       => (is => 'ro', default => sub { $HEBREW_MONTHS });

has year  => (is => 'rw', predicate => 1);
has month => (is => 'rw', predicate => 1);
has day   => (is => 'rw', predicate => 1);

with 'Date::Utils';

sub BUILD {
    my ($self) = @_;

    $self->validate_year($self->year)          if $self->has_year;
    $self->validate_hebrew_month($self->month) if $self->has_month;
    $self->validate_day($self->day)            if $self->has_day;

    unless ($self->has_year && $self->has_month && $self->has_day) {
        my $today = localtime;
        my $year  = $today->year + 1900;
        my $month = $today->mon + 1;
        my $day   = $today->mday;
        my $date  = $self->from_gregorian($year, $month, $day);
        $self->year($date->year);
        $self->month($date->month);
        $self->day($date->day);
    }
}

=head1 SYNOPSIS

    use strict; use warnings;
    use Date::Hebrew::Simple;

    # prints today's Hebrew date.
    print Date::Hebrew::Simple->new, "\n";

    my $date = Date::Hebrew::Simple->new({ year => 5778, month => 11, day => 1 });

    # prints the given Hebrew date
    print $date->as_string, "\n";

    # prints the equivalent Julian day
    print $date->to_julian, "\n";

    # prints the equivalent Gregorian date
    print sprintf("%04d-%02d-%02d", $date->to_gregorian), "\n";

    # prints day of the week index (0 for Yom Rishon, 1 for Yom Sheni and so on).
    print $date->day_of_week, "\n";

    # prints the Hebrew date equivalent of the Gregorian date (2018-02-12).
    print $date->from_gregorian(2018, 02, 12), "\n";

    # prints the Hebrew date equivalent of the Julian day (2458134.5).
    print $date->from_julian(2458134.5), "\n";

=head1 METHODS

=head2 to_julian()

Returns julian day equivalent of the Hebrew date.

=cut

sub to_julian {
    my ($self, $year, $month, $day) = @_;

    $day    = $self->day   unless defined $day;
    $month  = $self->month unless defined $month;
    $year   = $self->year  unless defined $year;
    my $months = $self->months_in_year($year);
    my $julian_day = $self->hebrew_epoch + $self->delay_1($year) + $self->delay_2($year) + $day + 1;

    if ($month < 7) {
        for (my $m = 7; $m <= $months; $m++) {
            $julian_day += $self->days_in_month_year($m, $year);
        }
        for (my $m = 1; $m < $month; $m++) {
            $julian_day += $self->days_in_month_year($m, $year);
        }
    }
    else {
        for (my $m = 7; $m < $month; $m++) {
            $julian_day += $self->days_in_month_year($m, $year);
        }
    }

    return $julian_day;
}

=head2 from_julian($julian_day)

Returns Hebrew date as an object of type L<Date::Hebrew::Simple> equivalent of the
the Julian date C<$julian_day>.

=cut

sub from_julian {
    my ($self, $julian_day) = @_;

    $julian_day = floor($julian_day) + 0.5;

    my $count = floor((($julian_day - $self->hebrew_epoch) * 98496.0) / 35975351.0);
    my $year = $count - 1;
    for (my $i = $count; $julian_day >= $self->to_julian($i, 7, 1); $i++) {
        $year++;
    }

    my $first = ($julian_day < $self->to_julian($year, 1, 1)) ? (7) : (1);
    my $month = $first;
    for (my $m = $first; $julian_day > $self->to_julian($year, $m, $self->days_in_month_year($m, $year)); $m++) {
        $month++;
    }

    my $day = ($julian_day - $self->to_julian($year, $month, 1)) + 1;
    return Date::Hebrew::Simple->new({ year => $year, month => $month, day => $day });
}

=head2 to_gregorian()

Returns gregorian date as list (yyyy,mm,dd) equivalent of the Hebrew date.

=cut

sub to_gregorian {
    my ($self) = @_;

    return $self->julian_to_gregorian($self->to_julian);
}

=head2 from_gregorian($year, $month, $day)

Returns Hebrew date as an object of type L<Date::Hebrew::Simple> equivalent of the
given Gregorian date C<$year>, C<$month> and C<$day>.

=cut

sub from_gregorian {
    my ($self, $year, $month, $day) = @_;

    $self->validate_date($year, $month, $day);
    my $julian_day = $self->gregorian_to_julian($year, $month, $day) + (floor(0 + 60 * (0 + 60 * 0) + 0.5) / 86400.0);
    return $self->from_julian($julian_day);
}

=head2 day_of_week()

Returns day of the week, starting 0 for Yom Rishon, 1 for Yom Sheni and so on.

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

=cut

sub day_of_week {
    my ($self) = @_;

    my $dow = $self->jwday($self->to_julian);
    if ($dow > 0) {
        return --$dow;
    }
    elsif ($dow == 0) {
        return 6;
    }
}

=head2 is_leap_year($year)

Returns 0 or 1 if the given Hebrew year C<$year> is a leap year or not.

=cut

sub is_leap_year {
    my ($self, $year) = @_;

    return ((($year * 7) + 1) % 19) < 7;
}

sub days_in_year {
    my ($self, $year) = @_;

    return $self->to_julian($year + 1, 7, 1) - $self->to_julian($year, 7, 1);
}

sub months_in_year {
    my ($self, $year) = @_;

    return $self->is_leap_year($year) ? (13) : (12);
}

sub delay_1 {
    my ($self, $year) = @_;

    my $months = floor(((235 * $year) - 234) / 19);
    my $parts  = 12084 + (13753 * $months);
    my $day    = ($months * 29) + floor($parts / 25920);

    if (((3 * ($day + 1)) % 7) < 3) {
        $day++;
    }

    return $day;

}

sub delay_2 {
    my ($self, $year) = @_;

    my $last    = $self->delay_1($year - 1);
    my $present = $self->delay_1($year);
    my $next    = $self->delay_1($year + 1);

    if (($next - $present) == 356) {
        return 2;
    }
    else {
        if (($present - $last) == 382) {
            return 1;
        }
        else {
            return 0;
        }
    }
}

sub days_in_month_year {
    my ($self, $month, $year) = @_;

    # First of all, dispose of fixed-length 29 day months
    if (($month == 2) || ($month == 4) || ($month == 6) || ($month == 10) || ($month == 13)) {
        return 29;
    }

    # If it's not a leap year, Adar has 29 days
    if (($month == 12) && !$self->is_leap_year($year)) {
        return 29;
    }

    # If it's Cheshvan, days depend on length of year
    if (($month == 8) && !(($self->days_in_year($year) % 10) == 5)) {
        return 29;
    }

    # Similarly, Kislev varies with the length of year
    if (($month == 9) && !(($self->days_in_year($year) % 10) == 3)) {
        return 29;
    }

    # Nope, it's a 30 day month
    return 30;
}

sub validate_hebrew_month {
    my ($self, $month, $year) = @_;

    $year = $self->year unless defined $year;
    if (defined $month && ($month !~ /^[-+]?\d+$/)) {
        return $self->validate_hebrew_month_name($month, $year);
    }

    my @caller = caller(0);
    @caller    = caller(2) if $caller[3] eq '(eval)';

    Date::Exception::InvalidMonth->throw({
        method      => __PACKAGE__."::validate_hebrew_month",
        message     => sprintf("ERROR: Invalid month [%s].", defined($month)?($month):('')),
        filename    => $caller[1],
        line_number => $caller[2] })
        unless (defined($month)
                && ($month =~ /^\+?\d+$/)
                && ($month >= 1)
                && (($self->is_leap_year($year) && $month <= 13)
                    || ($month <= 12)));
}

sub validate_hebrew_month_name {
    my ($self, $month_name, $year) = @_;

    my @caller = caller(0);
    @caller    = caller(2) if $caller[3] eq '(eval)';

    $year = $self->year unless defined $year;
    my $months = $self->months;
    if ($self->is_leap_year($year)) {
        $months->[12] = 'Adar I';
        $months->[13] = 'Adar II';
    }

    Date::Exception::InvalidMonth->throw({
        method      => __PACKAGE__."::validate_hebrew_month_name",
        message     => sprintf("ERROR: Invalid month name [%s].", defined($month_name)?($month_name):('')),
        filename    => $caller[1],
        line_number => $caller[2] })
        unless (defined($month_name) && ($month_name !~ /^[-+]?\d+$/) && (grep /$month_name/i, @{$months}[1..$#$months]));
}

sub get_month_name {
    my ($self, $month, $year) = @_;

    $year = $self->year unless defined $year;
    if (defined $month) {
        $self->validate_hebrew_month($month, $year);
    }
    else {
        $month = $self->month;
    }

    my $months = $self->months;
    if ($self->is_leap_year($year)) {
        $months->[12] = 'Adar I';
        $months->[13] = 'Adar II';
    }

    return $months->[$month];
}

sub as_string {
    my ($self) = @_;

    return sprintf("%d, %s %d", $self->day, $self->get_month_name, $self->year);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Date-Hebrew-Simple>

=head1 SEE ALSO

=over 4

=item L<Date::Bahai::Simple>

=item L<Date::Gregorian::Simple>

=item L<Date::Hijri::Simple>

=item L<Date::Persian::Simple>

=item L<Date::Saka::Simple>

=back

=head1 BUGS

Please report any bugs / feature requests to C<bug-date-hebrew-simple at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Hebrew-Simple>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Date::Hebrew::Simple

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Hebrew-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Date-Hebrew-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Date-Hebrew-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/Date-Hebrew-Simple/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
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

1; # End of Date::Hebrew::Simple
