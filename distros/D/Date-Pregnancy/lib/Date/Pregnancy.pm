package Date::Pregnancy;

use strict;
use warnings;
use DateTime;
use Carp;
use Clone qw(clone);
use POSIX qw(ceil);
use vars qw($VERSION @ISA @EXPORT_OK);
require Exporter;
use POSIX qw(floor);
use 5.008;    #5.8.0

$VERSION = '0.06';
@ISA     = qw(Exporter);

@EXPORT_OK = qw(
    calculate_birthday calculate_week calculate_month
    _countback _266days _40weeks
);

use constant AVG_CYCLE => 28;
use constant DAY       => ( 60 * 60 * 24 );

sub _40weeks {
    my $dt = shift
        || carp "first_day_of_last_period parameter is mandatory";
    return undef unless ( ref $dt );

    my $birthday = clone($dt);
    $birthday->add( weeks => 40 );

    return $birthday;
}

sub _266days {
    my ( $dt, $period_cycle_length ) = @_;

    unless ( ref $dt ) {
        carp "first_day_of_last_period parameter is mandatory";
        return undef;
    }

    if ( !$period_cycle_length ) {
        carp "period_cycle_length parameter is mandatory";
        return undef;
    }

    my $birthday = clone($dt);
    if ( $period_cycle_length > 28 ) {
        $birthday->add( seconds =>
                ( DAY * floor( $period_cycle_length * 0.85 * ( 2 / 3 ) ) ) );

    } elsif ( $period_cycle_length < 29 ) {
        $birthday->add( seconds => ( DAY * ( $period_cycle_length / 2 ) ) );
    }
    $birthday->add( days => 266 );

    return $birthday;
}

sub _countback {
    my $dt = shift
        || carp "first_day_of_last_period parameter is mandatory";
    return undef unless ( ref $dt );

    my $birthday = clone($dt);

    $birthday->add( days => 7 );
    $birthday->subtract( months => 3 );
    $birthday->add( years => 1 );

    #if ($dt->month < 3) {
    #}

    return $birthday;
}

sub calculate_birthday {
    my %params = @_;

    my $method = $params{'method'} || '266days';

    my $period_cycle_length = $params{'period_cycle_length'} || AVG_CYCLE;

    my $first_day_of_last_period = $params{'first_day_of_last_period'}
        || carp "first_day_of_last_period parameter is mandatory";
    return undef unless ( ref $first_day_of_last_period );

    my $calculation = "_$method";
    my @methods     = qw(_countback _266days _40weeks);

    unless ( grep {/$method/} @methods ) {
        croak "Unknown method: $params{'method'}";
    }

    $calculation .= '($first_day_of_last_period';

    if ( $method eq '266days' ) {
        $calculation .= ', $period_cycle_length';
    }
    $calculation .= ');';

    my $birthday = eval("$calculation");
    croak $@ if $@;

    return $birthday;
}

sub calculate_week {
    my %params = @_;

    my $period_cycle_length = $params{'period_cycle_length'} || AVG_CYCLE;

    my $now = $params{'date'} || DateTime->now;
    $now->set_time_zone('UTC');

    my $method = $params{'method'} || '40weeks';

    my $birthday;
    if ( $params{'birthday'} ) {
        $birthday = $params{'birthday'};

    } else {
        $birthday = calculate_birthday(
            first_day_of_last_period => $params{'first_day_of_last_period'},
            period_cycle_length      => $period_cycle_length,
            method                   => $method,
        );
        return undef unless ( ref $birthday );
    }
    $birthday->set_time_zone('UTC');

    $birthday->subtract( months => 9 );

    my $duration = $birthday->delta_days($now);

    return ( $duration->weeks + 1 );
}

sub calculate_month {
    my %params = @_;

    my $period_cycle_length = $params{'period_cycle_length'} || AVG_CYCLE;

    my $now = $params{'date'} || DateTime->now;
    $now->set_time_zone('UTC');

    my $method = $params{'method'} || '40weeks';

    my $birthday;
    if ( $params{'birthday'} ) {
        $birthday = $params{'birthday'};

    } else {
        $birthday = calculate_birthday(
            first_day_of_last_period => $params{'first_day_of_last_period'},
            period_cycle_length      => $period_cycle_length,
            method                   => $method,
        );
        return undef unless ( ref $birthday );
    }
    $birthday->set_time_zone('UTC');

    $birthday->subtract( months => 9 );

    my $duration = $birthday->delta_md($now);

    return ( $duration->months + 1 );
}

1;

__END__

=pod

=begin markdown

[![CPAN version](https://badge.fury.io/pl/Date-Pregnancy.svg)](http://badge.fury.io/pl/Date-Pregnancy)
[![Build Status](https://travis-ci.org/jonasbn/Date-Pregnancy.svg?branch=master)](https://travis-ci.org/jonasbn/Date-Pregnancy)
[![Coverage Status](https://coveralls.io/repos/jonasbn/Date-Pregnancy/badge.png)](https://coveralls.io/r/jonasbn/Date-Pregnancy)

=end markdown

=head1 NAME

Date::Pregnancy - calculate birthdate and week numbers for a pregnancy

=head1 VERSION

This documentation describes version 0.05

=head1 SYNOPSIS

	use Date::Pregnancy qw(calculate_birthday);

	my $dt = DateTime->new(
		year  => 2004,
		month => 3,
		day   => 19,
	);
	$birthday = calculate_birthday(first_day_of_last_period => $dt);

	$birthday = calculate_birthday(
		first_day_of_last_period => $dt,
		period_cycle_length      => 28,
	);


	use Date::Pregnancy qw(calculate_week);

	$week = calculate_week(first_day_of_last_period => $dt);

	$dt2 = DateTime->new(
		year  => 2004,
		month => 12,
		day   => 24,
	);

	$week = calculate_week(
		first_day_of_last_period => $dt,
		date                     => $dt2,
	);

	$week = calculate_week(
		first_day_of_last_period => $dt,
		method                   => '40weeks',
	);


	$week = calculate_week(birthday => $birthday);


	use Date::Pregnancy qw(calculate_month);

	$month = calculate_month(first_day_of_last_period => $dt);

	$month = calculate_month(
		first_day_of_last_period => $dt,
		date                     => $dt2,
	);

	$month = calculate_month(
		first_day_of_last_period => $dt,
		method                   => 'countback',
	);

	$week = calculate_month(birthday => $birthday);

=head1 DESCRIPTION

This module can be used to calculate the due date for a pregnancy, it implements
3 different methods, which will give different results.

The different methods are described below in detail (SEE: METHODS).

This module relies heavily on DateTime objects in order to calculate
dates of birth, week numbers and month numbers. It does however not
require Michael Schwern's module L<Sex>.

=head2 calculate_birthday

Calculates date of birth.

Takes one named parameter:

* first_day_of_last_period

Which should be a DateTime object indicating the first day of the last
period.

If the period cycle length varies from the average of 28 days,
you can optionally provide the named parameter:

* period_cycle_length

This defaults to 28.

The default method used for calculating date of birth is the 266 days
method (SEE: Methods). If you want to use one of the other methods you
can use the named parameter B<method> and specify either:

* 40weeks

* countback

The function returns a DateTime object indicating the calculated date of birth
or undef upon failure.

=head2 calculate_week

Calculates in what week the pregnant person currently is. A pregnancy
is on average 40 weeks; these week numbers are normally used when
talking pregnancy and most guides, books and websites refer to the
different stages of pregnancy using these week numbers.

Takes one named parameter:

* first_day_of_last_period

Which should be a DateTime object indicating the first day of the last
period.

Optionally you can provide it with a named B<date> parameter if you want
to calculate the week number for a given date. The date specified
should be a DateTime object, this defaults to now, when not provided.

Also a named parameter called B<birthday> can be provided, if you
already have a birthday DateTime object. If this is not provided
B<calculate_week> will call B<calculate_birthday> internally.

As for B<calculate_birthday> the function also takes the named parameter:

* first_day_of_last_period

and

* method

Please refer to B<calculate_birthday>.

The function returns an integer indicating the week of the pregnancy or
undef upon failure.

=head2 calculate_month

Calculates in what month the pregnant person currently is (see also
B<calculate_week>). A pregnancy is on average 9 months.

Takes one named parameter:

* first_day_of_last_period

Which should be a DateTime object indicating the first day of the last
period.

Optionally you can provide it with a named B<date> parameter if you want
to calculate the month number for a given date. The date specified
should be a DateTime object, this defaults to now, when not provided.

Also a named parameter called B<birthday> can be provided, as for
B<calculate_week>, if you already have a birthday DateTime object. If
this is not provided B<calculate_month> will call B<calculate_birthday>
internally.

As for B<calculate_birthday> the function also takes the named parameter:

* first_day_of_last_period

and

* method

Please refer to B<calculate_birthday>.

The function returns an integer indicating the month of the pregnancy
or undef upon failure.

=head1 METHODS

This module implements 3 different methods for calculating the date of
birth based on data such as first day of last period (LMP) and average period
cycle length (APCL).

The 3 methods are:

=over

=item 266 Days (the one used by default)

=item 40 Weeks

=item Count Back

=back

=head2 266 Days

This method uses the APCL together with the LMP.

It adds the APCL divided by 2 to the LMP in the case where APCL is
equal to or lower than the average of 28 days.

In the case where the APCL is higher than the average it adds the APCL
multiplied by 0.85 multiplied by 2 divided by 3 to the LMP.

=head2 40 Weeks

This method does not use the APCL, but simply counts 40 weeks, the
number of weeks in an average pregnancy from the LMP date.

=head2 Count Back

The count back method adds 7 days to the LMP, then deducts 3 months, and
finally adds 1 year to give the estimated date of birth.

=head1 TEST DATA

I am very interested in improving this module, so if you have the
opportunity of submitting me test data it is more than welcome.

The format should be either a test file (*.t), where you choose the
file name yourself (see t/Villads.t) or you simply submit me the date
of the first day of the last period for the pregnant person, the length of
time between periods (if this varies from the avarage of 28), and possibly
the result of your own/your doctor's week number calculation. I can
then use these data to validate the calculation methods used in this
module.

If possible please include the information on what method your doctor
is using if this is available (SEE: METHODS).

=head1 BUGS

Please report issues via CPAN RT:

  http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Pregnancy

or by sending mail to

  bug-Date-Pregnancy@rt.cpan.org

See the BUGS file for known bugs.

=head1 SEE ALSO

=over

=item L<DateTime>

=item L<Sex>

=item L<Time::Clock::Biological>

=item L<http://www.paternityangel.com/Articles_zone/How_it_happens/How-6.htm>

=item L<http://javascript.internet.com/calculators/pregnancy.html>

=item L<http://www.plus-size-pregnancy.org/figuring.htm>

=back

=head1 DISCLAIMER

The method of calculating day of birth and week numbers implemented in
this module is based on simple formulas.

The ultrasound scan is a much more accurate method and finally babies
seem to have a will of their own, so please do only use the results of
this module as a guideline, the author of this module cannot be held
responsible for the results of calculations based on use of this module.

Feedback is welcome though as well as test data (please see TEST DATA
above).

=head1 ACKNOWLEDGEMENTS

=over

=item * Nick Morrott, corrections to multiple spelling errors

=item * Thomas Eibner, who ALWAYS asks me whether I am a father by now
and acuses me of pregnant-talk (just because he cannot calculate the
weeks), now he can find out by looking at the tests included in this
module or by using this module.

=item * Lars Balker Rasmussen, who could not find Date-Pregnancy in his include
path "lbr can't locate Date/Pregnancy.pm in @INC" - Now he has no
excuse L<Date::Pregnancy> is a reality.

=item * Lars Thegler for making me revisit the alpha version.

=back

=head1 AUTHOR

Jonas B. Nielsen, (jonasbn) - C<< <jonasbn@cpan.org> >>

=head1 COPYRIGHT

Date-Pregnancy is (C) by Jonas B. Nielsen, (jonasbn) 2004-2016

Date-Pregnancy is released under the artistic license 2.0

=cut
