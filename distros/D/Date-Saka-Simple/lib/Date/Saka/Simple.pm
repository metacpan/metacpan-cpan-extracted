package Date::Saka::Simple;

$Date::Saka::Simple::VERSION   = '0.24';
$Date::Saka::Simple::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Date::Saka::Simple - Represents Saka date.

=head1 VERSION

Version 0.24

=cut

use 5.006;
use Data::Dumper;
use Time::localtime;
use List::Util qw/min/;
use POSIX qw/floor/;
use Date::Calc qw(Add_Delta_Days Delta_Days);
use Date::Exception::InvalidDayCount;
use Date::Exception::InvalidMonthCount;
use Date::Exception::InvalidYearCount;

use Moo;
use namespace::autoclean;

use overload q{""} => 'as_string', fallback => 1;

=head1 DESCRIPTION

Represents the Saka date.

=cut

my $SAKA_START  = 80;
my $SAKA_OFFSET = 78;

my $SAKA_MONTHS = [
    undef,
    'Chaitra', 'Vaisakha', 'Jyaistha',   'Asadha', 'Sravana', 'Bhadra',
    'Asvina',  'Kartika',  'Agrahayana', 'Pausa',  'Magha',   'Phalguna'
];

my $SAKA_DAYS = [
    'Ravivara', 'Somvara', 'Mangalavara', 'Budhavara',
    'Brahaspativara', 'Sukravara', 'Sanivara'
];

has days        => (is => 'ro', default => sub { $SAKA_DAYS   });
has months      => (is => 'ro', default => sub { $SAKA_MONTHS });
has saka_start  => (is => 'ro', default => sub { $SAKA_START  });
has saka_offset => (is => 'ro', default => sub { $SAKA_OFFSET });

has year  => (is => 'rw', predicate => 1);
has month => (is => 'rw', predicate => 1);
has day   => (is => 'rw', predicate => 1);

with 'Date::Utils';

sub BUILD {
    my ($self) = @_;

    $self->validate_year($self->year)   if $self->has_year;
    $self->validate_month($self->month) if $self->has_month;
    $self->validate_day($self->day)     if $self->has_day;

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
    use Date::Saka::Simple;

    # prints today's Saka date
    print Date::Saka::Simple->new, "\n";

    my $date = Date::Saka::Simple->new({ year => 1937, month => 1, day => 1 });

    # prints the given Saka date
    print $date->as_string, "\n";

    # prints the equivalent Julian date
    print $date->to_julian, "\n";

    # prints the equivalent Gregorian date
    print sprintf("%04d-%02d-%02d", $date->to_gregorian), "\n";

    # prints day of the week index (0 for Ravivara, 1 for Somvara and so on).
    print $date->day_of_week, "\n";

    # add days to the given Saka date and print
    print $date->add_days(2)->as_string, "\n";

    # minus days to the given Saka date and print
    print $date->minus_days(2)->as_string, "\n";

    # add months to the given Saka date and print
    print $date->add_months(2)->as_string, "\n";

    # minus months to the given Saka date and print
    print $date->minus_months(2)->as_string, "\n";

    # add years to the given Saka date and print
    print $date->add_years(2)->as_string, "\n";

    # minus years to the given Saka date and print
    print $date->minus_years(2)->as_string, "\n";

=head1 METHODS

=head2 to_julian()

Returns julian date equivalent of the Saka date.

=cut

sub to_julian {
    my ($self) = @_;

    my $gregorian_year = $self->year + 78;
    my $gregorian_day  = ($self->is_gregorian_leap_year($gregorian_year)) ? (21) : (22);
    my $start = $self->gregorian_to_julian($gregorian_year, 3, $gregorian_day);

    my ($julian);
    if ($self->month == 1) {
        $julian = $start + ($self->day - 1);
    }
    else {
        my $chaitra = ($self->is_gregorian_leap_year($gregorian_year)) ? (31) : (30);
        $julian = $start + $chaitra;
        my $_month = $self->month - 2;
        $_month = min($_month, 5);
        $julian += $_month * 31;

        if ($self->month >= 8) {
            $_month  = $self->month - 7;
            $julian += $_month * 30;
        }

        $julian += $self->day - 1;
    }

    return $julian;
}

=head2 from_julian($julian_date)

Returns  Saka  date  as an object of type L<Date::Saka::Simple> equivalent of the
Julian date C<$julian_date>.

=cut

sub from_julian {
    my ($self, $julian_date) = @_;

    $julian_date = floor($julian_date) + 0.5;
    my $year     = ($self->julian_to_gregorian($julian_date))[0];
    my $yday     = $julian_date - $self->gregorian_to_julian($year, 1, 1);
    my $chaitra  = $self->days_in_chaitra($year);
    $year = $year - $self->saka_offset;

    if ($yday < $self->saka_start) {
        $year--;
        $yday += $chaitra + (31 * 5) + (30 * 3) + 10 + $self->saka_start;
    }
    $yday -= $self->saka_start;

    my ($day, $month);
    if ($yday < $chaitra) {
        $month = 1;
        $day   = $yday + 1;
    }
    else {
        my $mday = $yday - $chaitra;
        if ($mday < (31 * 5)) {
            $month = floor($mday / 31) + 2;
            $day   = ($mday % 31) + 1;
        }
        else {
            $mday -= 31 * 5;
            $month = floor($mday / 30) + 7;
            $day   = ($mday % 30) + 1;
        }
    }

    return Date::Saka::Simple->new({ year => $year, month => $month, day => $day });
}

=head2 to_gregorian()

Returns gregorian date as list (yyyy,mm,dd) equivalent of the Saka date.

=cut

sub to_gregorian {
    my ($self) = @_;

    return $self->julian_to_gregorian($self->to_julian);
}

=head2 from_gregorian($year, $month, $day)

Returns  Saka  date  as an object of type L<Date::Saka::Simple> equivalent of the
given Gregorian date C<$year>, C<$month> and C<$day>.

=cut

sub from_gregorian {
    my ($self, $year, $month, $day) = @_;

    return $self->from_julian($self->gregorian_to_julian($year, $month, $day));
}

=head2 day_of_week()

Returns day of the week, starting 0 for Ravivara, 1 for Somvara and so on.

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

=cut

sub day_of_week {
    my ($self) = @_;

    return $self->jwday($self->to_julian);
}

=head2 add_days()

Add given number of days to the Saka date.

=cut

sub add_days {
    my ($self, $no_of_days) = @_;

    my @caller = caller(0);
    @caller    = caller(2) if $caller[3] eq '(eval)';

    Date::Exception::InvalidDayCount->throw({
        method      => __PACKAGE__."::add_days",
        message     => 'ERROR: Invalid day count.',
        filename    => $caller[1],
        line_number => $caller[2] })
        unless ($no_of_days =~ /^\-?\d+$/);

    my ($year, $month, $day) = $self->to_gregorian();
    ($year, $month, $day) = Add_Delta_Days($year, $month, $day, $no_of_days);
    my $date = Date::Saka::Simple->new->from_gregorian($year, $month, $day);

    $self->year($date->year);
    $self->month($date->month);
    $self->day($date->day);

    return $self;
}

=head2 minus_days()

Minus given number of days from the Saka date.

=cut

sub minus_days {
    my ($self, $no_of_days) = @_;

    my @caller = caller(0);
    @caller    = caller(2) if $caller[3] eq '(eval)';

    Date::Exception::InvalidDayCount->throw({
        method      => __PACKAGE__."::minus_days",
        message     => 'ERROR: Invalid day count.',
        filename    => $caller[1],
        line_number => $caller[2] })
        unless ($no_of_days =~ /^\d+$/);

    $self->add_days(-1 * $no_of_days);

    return $self;
}

=head2 add_months()

Add given number of months to the Saka date.

=cut

sub add_months {
    my ($self, $no_of_months) = @_;

    my @caller = caller(0);
    @caller    = caller(2) if $caller[3] eq '(eval)';

    Date::Exception::InvalidMonthCount->throw({
        method      => __PACKAGE__."::add_months",
        message     => 'ERROR: Invalid month count.',
        filename    => $caller[1],
        line_number => $caller[2] })
        unless ($no_of_months =~ /^\d+$/);

    if (($self->month + $no_of_months) > 12) {
        while (($self->month + $no_of_months) > 12) {
            my $_month = 12 - $self->month;
            $self->year($self->year + 1);
            $self->month(1);
            $no_of_months = $no_of_months - ($_month + 1);
        }
    }

    $self->month($self->month + $no_of_months);

    return $self;
}

=head2 minus_months()

Minus given number of months from the Saka date.

=cut

sub minus_months {
    my ($self, $no_of_months) = @_;

    my @caller = caller(0);
    @caller    = caller(2) if $caller[3] eq '(eval)';

    Date::Exception::InvalidMonthCount->throw({
        method      => __PACKAGE__."::minus_months",
        message     => 'ERROR: Invalid month count.',
        filename    => $caller[1],
        line_number => $caller[2] })
        unless ($no_of_months =~ /^\d+$/);

    if (($self->month - $no_of_months) < 1) {
        while (($self->{mm} - $no_of_months) < 1) {
            my $_month = $no_of_months - $self->month;
            $self->year($self->year - 1);
            $no_of_months = $no_of_months - $self->month;
            $self->month(12);
        }
    }

    $self->month($self->month - $no_of_months);

    return $self;
}

=head2 add_years()

Add given number of years to the Saka date.

=cut

sub add_years {
    my ($self, $no_of_years) = @_;

    my @caller = caller(0);
    @caller    = caller(2) if $caller[3] eq '(eval)';

    Date::Exception::InvalidYearCount->throw({
        method      => __PACKAGE__."::add_years",
        message     => 'ERROR: Invalid year count.',
        filename    => $caller[1],
        line_number => $caller[2] })
        unless ($no_of_years =~ /^\d+$/);

    $self->year($self->year + $no_of_years);

    return $self;
}

=head2 minus_years()

Minus given number of years from the Saka date.

=cut

sub minus_years {
    my ($self, $no_of_years) = @_;

    my @caller = caller(0);
    @caller    = caller(2) if $caller[3] eq '(eval)';

    Date::Exception::InvalidYearCount->throw({
        method      => __PACKAGE__."::minus_years",
        message     => 'ERROR: Invalid year count.',
        filename    => $caller[1],
        line_number => $caller[2] })
        unless ($no_of_years =~ /^\d+$/);

    $self->year($self->year - $no_of_years);

    return $self;
}

sub days_in_chaitra {
    my ($self, $year) = @_;

    $self->days_in_month_year(1, $year);
}

sub days_in_month_year {
    my ($self, $month, $year) = @_;

    if ($month == 1) {
        return ($self->is_gregorian_leap_year($year)) ? (return 31) : (return 30);
    }
    else {
        my @start = Date::Saka::Simple->new({ year => $year, month => $month, day => 1 })->to_gregorian;
        if ($month == 12) {
            $year += 1;
            $month = 1;
        }
        else {
            $month += 1;
        }

        my @end = Date::Saka::Simple->new({ year => $year, month => $month, day => 1 })->to_gregorian;

        return Delta_Days(@start, @end);
    }
}

sub as_string {
    my ($self) = @_;

    return sprintf("%02d, %s %04d", $self->day, $self->get_month_name, $self->year);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Date-Saka-Simple>

=head1 SEE ALSO

=over 4

=item L<Date::Bahai::Simple>

=item L<Date::Gregorian::Simple>

=item L<Date::Hebrew::Simple>

=item L<Date::Hijri::Simple>

=item L<Date::Julian::Simple>

=item L<Date::Persian::Simple>

=back

=head1 BUGS

Please report any bugs / feature requests to C<bug-date-saka-simple at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Saka-Simple>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Date::Saka::Simple

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Saka-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Date-Saka-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Date-Saka-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/Date-Saka-Simple/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 - 2016 Mohammad S Anwar.

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

1; # End of Date::Saka::Simple
