use strict;
use warnings;

use Test::More tests => 28;

use constant DURATION => 'DateTime::Fiction::JRRTolkien::Shire::Duration';

use_ok( DURATION )
    or BAIL_OUT( $@ );

# NOTE that we ONLY test the duration object in this test. That means we MUST NOT test compare().

{
    my $dur = DURATION->new(
	years	=> 1,
	months	=> 2,
	weeks	=> 3,
	days	=> 4,
    );

    my %want = (
	years	=> 1,
	months	=> 2,
	weeks	=> 3,
	days	=> 4,
	map { $_ => 0 } qw{ minutes seconds nanoseconds },
    );

    my %sum = (
	years	=> 1,
	months	=> 3,
	weeks	=> 2,
	days	=> 4,
	map { $_ => 0 } qw{ minutes seconds nanoseconds },
    );

    ok( $dur->is_positive(), 'Duration is positive' );

    ok( ! $dur->is_zero(), 'Duration is not zero' );

    ok( ! $dur->is_negative(), 'Duration is not negative' );

    is_deeply( { $dur->deltas() }, \%want, 'Weeks are preserved' );

    cmp_ok( $dur->delta_years(), '==', 1, 'delta_years() is 1' );

    cmp_ok( $dur->delta_months(), '==', 2, 'delta_months() is 2' );

    cmp_ok( $dur->delta_weeks(), '==', 3, 'delta_weeks() is 3' );

    cmp_ok( $dur->delta_days(), '==', 4, 'delta_days() is 4' );

    cmp_ok( $dur->delta_minutes(), '==', 0, 'delta_minutes() is 0' );

    cmp_ok( $dur->delta_seconds(), '==', 0, 'delta_seconds() is 0' );

    cmp_ok( $dur->delta_nanoseconds(), '==', 0, 'delta_nanoseconds() is 0' );

    cmp_ok( $dur->years(), '==', 1, 'years() is 1' );

    cmp_ok( $dur->months(), '==', 2, 'months() is 2' );

    cmp_ok( $dur->weeks(), '==', 3, 'weeks() is 3' );

    cmp_ok( $dur->days(), '==', 4, 'days() is 4' );

    cmp_ok( $dur->hours(), '==', 0, 'hours() is 0' );

    cmp_ok( $dur->minutes(), '==', 0, 'minutes() is 0' );

    cmp_ok( $dur->seconds(), '==', 0, 'seconds() is 0' );

    cmp_ok( $dur->nanoseconds(), '==', 0, 'nanoseconds() is 0' );

    is_deeply( { $dur->inverse()->deltas() }, {
	    years	=> -1,
	    months	=> -2,
	    weeks	=> -3,
	    days	=> -4,
	    map { $_ => 0 } qw{ minutes seconds nanoseconds },
	}, 'Inverse' );

    is_deeply( { $dur->calendar_duration()->deltas() }, \%want,
	'Calendar duration' );

    is_deeply( { $dur->clock_duration()->deltas() }, {
	    map { $_ => 0 } qw{
		years months weeks days minutes seconds nanoseconds
	    },
	}, 'Clock duration' );

    $dur->add( months => 1, weeks => -1 );

    is_deeply( { $dur->deltas() }, \%sum,
	'Add one month less one week' );

    $dur->subtract( months => 1, weeks => -1 );

    is_deeply( { $dur->deltas() }, \%want,
	'Subtract one month less one week' );

    my $delta = DURATION->new( months => 1, weeks => -1 );

    $dur += $delta;

    is_deeply( { $dur->deltas() }, \%sum,
	'Add one month less one week using overload' );

    $dur -= $delta;

    is_deeply( { $dur->deltas() }, \%want,
	'Subtract one month less one week using overload' );

    is_deeply( { ( $dur * 2 )->deltas() }, {
	    years	=> 2,
	    months	=> 4,
	    weeks	=> 6,
	    days	=> 8,
	    map { $_ => 0 } qw{ minutes seconds nanoseconds },
	}, 'Multiply by two using overload' );

}

# ex: set textwidth=72 :
