package Date::Gregorian::Simple;

$Date::Gregorian::Simple::VERSION   = '0.14';
$Date::Gregorian::Simple::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Date::Gregorian::Simple - Represents Gregorian date.

=head1 VERSION

Version 0.14

=cut

use 5.006;
use Data::Dumper;
use Time::localtime;
use Date::Exception::InvalidDay;

use Moo;
use namespace::autoclean;

use overload q{""} => 'as_string', fallback => 1;

=head1 DESCRIPTION

Represents the Gregorian date.

=cut

our $GREGORIAN_MONTHS = [
    undef,
    qw(January February March     April   May      June
       July    August   September October November December)
];

our $GREGORIAN_DAYS = [
    qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)
];

our $GREGORIAN_MONTH_DAYS = [
    qw(31 28 31 30 31 30
       31 31 30 31 30 31)
];

has days   => (is => 'ro', default   => sub { $GREGORIAN_DAYS   });
has months => (is => 'ro', default   => sub { $GREGORIAN_MONTHS });
has year   => (is => 'rw', predicate => 1);
has month  => (is => 'rw', predicate => 1);
has day    => (is => 'rw', predicate => 1);

with 'Date::Utils';

sub BUILD {
    my ($self) = @_;

    if ($self->has_year && $self->has_month && $self->has_day) {
        $self->validate_year($self->year);
        $self->validate_month($self->month);
        if ($self->is_leap_year($self->year)) {
            my $day    = $self->day;
            my @caller = caller(0);
            @caller    = caller(2) if $caller[3] eq '(eval)';

            Date::Exception::InvalidDay->throw({
                method      => __PACKAGE__."::validate_day",
                message     => sprintf("ERROR: Invalid day [%s].", defined($day)?($day):('')),
                filename    => $caller[1],
                line_number => $caller[2] })
                unless (defined($day) && ($day =~ /^\d+$/) && ($day >= 1) && ($day <= 29));
        }
        else {
            $self->validate_day($self->day);
        }
    }
    else {
        my $today = localtime;
        $self->year($today->year + 1900);
        $self->month($today->mon + 1);
        $self->day($today->mday);
    }
}

=head1 SYNOPSIS

    use strict; use warnings;
    use Date::Gregorian::Simple;

    # prints today's Gregorian date
    print Date::Gregorian::Simple->new, "\n";

    my $date = Date::Gregorian::Simple->new({ year => 2016, month => 1, day => 1 });

    # prints the given Gregorian date
    print $date->as_string, "\n";

    # prints the equivalent Julian date
    print $date->to_julian, "\n";

    # prints day of the week index (0 for Sunday, 1 for Monday and so on).
    print $date->day_of_week, "\n";

    # prints the Gregorian date equivalent of the Julian date (2456955.5).
    print $date->from_julian(2456955.5), "\n";

=head1 METHODS

=head2 to_julian()

Returns Julian date equivalent of the Gregorian date.

=cut

sub to_julian {
    my ($self) = @_;

    return $self->gregorian_to_julian($self->year, $self->month, $self->day);
}

=head2 from_julian($julian_date)

Returns Gregorian date as an object of type L<Date::Gregorian::Simple> equivalent
of the given Julian date C<$julian_date>.

=cut

sub from_julian {
    my ($self, $julian_date) = @_;

    my ($year, $month, $day) = $self->julian_to_gregorian($julian_date);

    return Date::Gregorian::Simple->new({
        year  => $year,
        month => $month,
        day   => $day });
}

=head2 day_of_week()

Returns day of the week, starting 0 for Sunday, 1 for Monday and so on.

    +-------+-------------------------------------------------------------------+
    | Index | English Name                                                      |
    +-------+-------------------------------------------------------------------+
    |   0   | Sunday                                                            |
    |   1   | Monday                                                            |
    |   2   | Tuesday                                                           |
    |   3   | Wednesday                                                         |
    |   4   | Thursday                                                          |
    |   5   | Friday                                                            |
    |   6   | Saturday                                                          |
    +-------+-------------------------------------------------------------------+

=cut

sub day_of_week {
    my ($self) = @_;

    return $self->jwday($self->to_julian);
}

=head2 is_leap_year($year)

Returns 0 or 1 if the given Gregorian year C<$year> is a leap year or not.

=cut

sub is_leap_year {
    my ($self, $year) = @_;

    return $self->is_gregorian_leap_year($year);
}

sub days_in_year {
    my ($self, $year) = @_;

    ($self->is_leap_year($year))
    ?
    (return 366)
    :
    (return 365);
}

sub days_in_month_year {
    my ($self, $month, $year) = @_;

    if ($self->is_leap_year($year)) {
        return 29 if ($month == 2);
    }

    return $GREGORIAN_MONTH_DAYS->[$month-1];
}

sub as_string {
    my ($self) = @_;

    return sprintf("%d, %s %d", $self->day, $self->get_month_name, $self->year);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Date-Gregorian-Simple>

=head1 SEE ALSO

=over 4

=item L<Date::Bahai::Simple>

=item L<Date::Hijri::Simple>

=item L<Date::Hebrew::Simple>

=item L<Date::Julian::Simple>

=item L<Date::Persian::Simple>

=item L<Date::Saka::Simple>

=back

=head1 BUGS

Please report any bugs / feature requests to C<bug-date-gregorian-simple at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Gregorian-Simple>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Date::Gregorian::Simple

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Gregorian-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Date-Gregorian-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Date-Gregorian-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/Date-Gregorian-Simple/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016 - 2017 Mohammad S Anwar.

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

1; # End of Date::Gregorian::Simple
