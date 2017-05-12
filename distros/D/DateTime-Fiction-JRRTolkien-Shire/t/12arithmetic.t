use strict;
use warnings;

use DateTime::Fiction::JRRTolkien::Shire;
use Test::More tests => 37;

use constant DATE => 'DateTime::Fiction::JRRTolkien::Shire';

{
    my $dt = DATE->new(
	year	=> 1419,
	month	=> 3,
	day	=> 25,
    );

    $dt->add( days => 1 );

    is( $dt->ymd(), '1419-03-26', 'Add one day to Ring Day' );
}

{
    my $dt = DATE->new(
	year	=> 1419,
	month	=> 3,
	day	=> 30,
    );

    $dt->add( days => 1 );

    is( $dt->ymd(), '1419-04-01', 'Add one day to 30 Rethe' );
}

{
    my $dt = DATE->new(
	year	=> 1419,
	month	=> 6,
	day	=> 30,
    );

    $dt->add( days => 1 );

    is( $dt->ymd(), '1419-1Li', 'Add one day to 30 Forelithe' );

    $dt->add( days => 1 );

    is( $dt->ymd(), '1419-Myd', 'Add one day to 1 Lithe' );
}

{
    my $dt = DATE->new(
	year	=> 1419,
	month	=> 3,
	day	=> 25,
    );

    $dt->add( weeks => 1 );

    is( $dt->ymd(), '1419-04-02', 'Add one week to Ring Day' );
}

{
    my $dt = DATE->new(
	year	=> 1418,
	month	=> 12,
	day	=> 25,
    );

    $dt->add( weeks => 1 );

    is( $dt->ymd(), '1419-2Yu', 'Add one week to 1418-12-25' );
}

{
    my $dt = DATE->new(
	year	=> 1419,
	holiday	=> 3,
    );

    $dt->add( weeks => 1 );

    is( $dt->ymd(), '1419-07-07', q<Add one week to 1419 Midyear's day> );
}

{
    my $dt = DATE->new(
	year	=> 1419,
	month	=> 6,
	day	=> 30,
    );

    $dt->add( weeks => 1 );

    is( $dt->ymd(), '1419-07-05', 'Add one week to 1419-06-30' );
}

{
    my $dt = DATE->new(
	year	=> 1419,
	month	=> 3,
	day	=> 25,
    );

    $dt->add( months => 1 );

    is( $dt->ymd(), '1419-04-25', 'Add one month to Ring Day' );
}

{
    my $dt = DATE->new(
	year	=> 1419,
	holiday	=> 2,
    );

    $dt->add( months => 1 );

    is( $dt->ymd(), '1419-08-01', 'Add one month to 1419 1 Lithe' );
}

{
    my $dt = DATE->new(
	year	=> 1419,
	holiday	=> 2,
    );

    $dt->add( months => 1, holiday => 'backward' );

    is( $dt->ymd(), '1419-07-30',
	'Add one month to 1419 1 Lithe, backward mode' );
}

{
    my $dt = DATE->new(
	year	=> 1419,
	month	=> 3,
	day	=> 25,
    );

    $dt->add( months => 6 );

    is( $dt->ymd(), '1419-09-25', 'Add six months to Ring Day' );
}

{
    my $dt = DATE->new(
	year	=> 1419,
	month	=> 3,
	day	=> 25,
    );

    $dt->add( years => 1 );

    is( $dt->ymd(), '1420-03-25', 'Add one year to Ring Day' );
}

{
    my $dt = DATE->new(
	year	=> 1420,
	holiday	=> 4,
    );

    $dt->add( years => 1 );

    is( $dt->ymd(), '1421-2Li', 'Add one year to Overlithe' );
}

{
    my $dt = DATE->new(
	year	=> 1420,
	holiday	=> 4,
    );

    $dt->add( years => 1, holiday => 'backward' );

    is( $dt->ymd(), '1421-Myd', 'Add one year to Overlithe, backward mode' );
}

{
    my $dt = DATE->new(
	year	=> 1419,
	month	=> 3,
	day	=> 25,
    );

    $dt->subtract( days => 1 );

    is( $dt->ymd(), '1419-03-24', 'Subtract one day from Ring Day' );
}

{
    my $dt = DATE->new(
	year	=> 1419,
	month	=> 3,
	day	=> 25,
    );

    $dt->subtract( days => 25 );

    is( $dt->ymd(), '1419-02-30', 'Subtract 25 days from Ring Day' );
}

{
    my $dt = DATE->new(
	year	=> 1419,
	holiday	=> 3,
    );

    $dt->subtract( days => 1 );

    is( $dt->ymd(), '1419-1Li', q<Subtract one day from Midyear's day> );

    $dt->subtract( days => 1 );

    is( $dt->ymd(), '1419-06-30', 'Subtract one day from 1 Lithe' );
}

{
    my $dt = DATE->new(
	year	=> 1419,
	month	=> 4,
	day	=> 2,
    );

    $dt->subtract( weeks => 1 );

    is( $dt->ymd(), '1419-03-25', 'Subtract one week from 2 Astron' );
}

{
    my $dt = DATE->new(
	year	=> 1419,
	holiday	=> 1,
    );

    $dt->subtract( weeks => 1 );

    is( $dt->ymd(), '1418-12-25', 'Subtract one week from 1419 2 Yule' );
}

{
    my $dt = DATE->new(
	year	=> 1419,
	holiday	=> 3,
    );

    $dt->add( weeks => -1 );

    is( $dt->ymd(), '1419-06-24',
	q<Add minus one week to 1419 Midyear's day> );
}

{
    my $dt = DATE->new(
	year	=> 1419,
	holiday	=> 3,
    );

    $dt->subtract( weeks => 1 );

    is( $dt->ymd(), '1419-06-24',
	q<Subtract one week from 1419 Midyear's day> );
}

{
    my $dt = DATE->new(
	year	=> 1419,
	holiday	=> 3,
    );

    $dt->subtract( weeks => 1, holiday => 'backward' );

    is( $dt->ymd(), '1419-06-24',
	q<Subtract one week from 1419 Midyear's day, backward mode> );
}

{
    my $dt = DATE->new(
	year	=> 1419,
	holiday	=> 3,
    );

    $dt->subtract( weeks => 1, holiday => 'forward' );

    is( $dt->ymd(), '1419-06-25',
	q<Subtract one week from 1419 Midyear's day, forward mode> );
}

{
    my $dt = DATE->new(
	year	=> 1419,
	month	=> 7,
	day	=> 5,
    );

    $dt->subtract( weeks => 1 );

    is( $dt->ymd(), '1419-06-30', 'Subtract one week from 1419-07-05' );
}

{
    my $dt = DATE->new(
	year	=> 1419,
	month	=> 3,
	day	=> 25,
    );

    $dt->subtract( months => 1 );

    is( $dt->ymd(), '1419-02-25', 'Subtract one month from Ring Day' );
}

{
    my $dt = DATE->new(
	year	=> 1419,
	holiday	=> 2,
    );

    $dt->subtract( months => 1 );

    is( $dt->ymd(), '1419-05-30', 'Subtract one month from 1419 1 Lithe' );
}

{
    my $dt = DATE->new(
	year	=> 1419,
	holiday	=> 2,
    );

    $dt->subtract( months => 1, holiday => 'forward' );

    is( $dt->ymd(), '1419-06-01',
	'Subtract one month from 1419 1 Lithe, forward mode' );
}

{
    my $dt = DATE->new(
	year	=> 1419,
	month	=> 3,
	day	=> 25,
    );

    $dt->subtract( months => 6 );

    is( $dt->ymd(), '1418-09-25', 'Subtract six months from Ring Day' );
}

{
    my $dt = DATE->new(
	year	=> 1419,
	month	=> 3,
	day	=> 25,
    );

    $dt->subtract( years => 1 );

    is( $dt->ymd(), '1418-03-25', 'Subtract one year from Ring Day' );
}

{
    my $dt = DATE->new(
	year	=> 1420,
	holiday	=> 4,
    );

    $dt->subtract( years => 1 );

    is( $dt->ymd(), '1419-Myd', 'Subtract one year from Overlithe' );
}

{
    my $dt = DATE->new(
	year	=> 1420,
	holiday	=> 4,
    );

    $dt->subtract( years => 1, holiday => 'forward' );

    is( $dt->ymd(), '1419-2Li',
	'Subtract one year to Overlithe, forward mode' );
}

{
    my $dt1 = DATE->new(
	year	=> 1419,
	month	=> 3,
	day	=> 25,
    );

    my $dt2 = DATE->new(
	year	=> 1419,
	month	=> 3,
	day	=> 24,
    );

    is_deeply( { $dt1->subtract_datetime( $dt2 )->deltas() }, {
	    years	=> 0,
	    months	=> 0,
	    weeks	=> 0,
	    days	=> 1,
	    minutes	=> 0,
	    seconds	=> 0,
	    nanoseconds	=> 0,
	}, '25 Rethe - 24 Rethe' );
}

{
    my $dt1 = DATE->new(
	year	=> 1419,
	month	=> 3,
	day	=> 25,
    );

    my $dt2 = DATE->new(
	year	=> 1418,
	month	=> 1,
	day	=> 20,
    );

    is_deeply( { $dt1->subtract_datetime( $dt2 )->deltas() }, {
	    years	=> 1,
	    months	=> 2,
	    weeks	=> 0,
	    days	=> 5,
	    minutes	=> 0,
	    seconds	=> 0,
	    nanoseconds	=> 0,
	}, '25 Rethe 1419 - 20 Afteryule 1417' );
}

{
    my $dt1 = DATE->new(
	year	=> 1419,
	holiday	=> 2,
    );

    my $dt2 = DATE->new(
	year	=> 1419,
	month	=> 6,
	day	=> 30,
    );

    is_deeply( { $dt1->subtract_datetime( $dt2 )->deltas() }, {
	    years	=> 0,
	    months	=> 0,
	    weeks	=> 0,
	    days	=> 1,
	    minutes	=> 0,
	    seconds	=> 0,
	    nanoseconds	=> 0,
	}, '1 Lithe - 30 Forelithe' );
}

{
    my $dt1 = DATE->new(
	year	=> 1419,
	month	=> 3,
	day	=> 25,
    );

    my $dt2 = DATE->new(
	year	=> 1419,
	month	=> 3,
	day	=> 24,
    );

    is_deeply( { $dt1->subtract_datetime_absolute( $dt2 )->deltas() }, {
	    years	=> 0,
	    months	=> 0,
	    weeks	=> 0,
	    days	=> 0,
	    minutes	=> 0,
	    seconds	=> 86400,
	    nanoseconds	=> 0,
	}, '25 Rethe - 24 Rethe, absolute' );
}

# ex: set textwidth=72 :
