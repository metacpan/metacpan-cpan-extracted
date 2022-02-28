package main;

use 5.008004;

use strict;
use warnings;

use DateTime::Calendar::Christian;
use Test::More 0.88;	# Because of done_testing();

{   # Lifted shamelessly from DateTime t/03components.t
    my $d = DateTime::Calendar::Christian->new(
        year      => 2001,
        month     => 7,
        day       => 5,
        hour      => 2,
        minute    => 12,
        second    => 50,
        time_zone => 'UTC',
    );

    is( $d->day_of_quarter,   5,          '->day_of_quarter' );
    is( $d->doq,              5,          '->doq' );
    is( $d->day_of_quarter_0, 4,          '->day_of_quarter_0' );
    ok( !$d->is_last_day_of_quarter, '->is_last_day_of_quarter' );
    is( $d->quarter_length, 92,  '->quarter_length' );
    is( $d->quarter_abbr, 'Q3',          '->quarter_abbr' );
    is( $d->quarter_name, '3rd quarter', '->quarter_name' );
}

{
    my $dt = DateTime::Calendar::Christian->new( year => 1995, month => 2, day => 1 );

    is( $dt->quarter,        1,  '->quarter is 1' );
    is( $dt->day_of_quarter, 32, '->day_of_quarter' );
    is( $dt->quarter_length, 90, '->quarter_length' );
}

{
    my $dt = DateTime::Calendar::Christian->new( year => 1995, month => 5, day => 1 );

    is( $dt->quarter,        2,  '->quarter is 2' );
    is( $dt->day_of_quarter, 31, '->day_of_quarter' );
    is( $dt->quarter_length, 91, '->quarter_length' );
}

{
    my $dt = DateTime::Calendar::Christian->new( year => 1995, month => 8, day => 1 );

    is( $dt->quarter,        3,  '->quarter is 3' );
    is( $dt->day_of_quarter, 32, '->day_of_quarter' );
    is( $dt->quarter_length, 92, '->quarter_length' );
}

{
    my $dt = DateTime::Calendar::Christian->new( year => 1995, month => 11, day => 1 );

    is( $dt->quarter,        4,  '->quarter is 4' );
    is( $dt->day_of_quarter, 32, '->day_of_quarter' );
    is( $dt->quarter_length, 92, '->quarter_length' );
}

{
    my $dt = DateTime::Calendar::Christian->new( year => 1996, month => 2, day => 1 );

    is( $dt->quarter,        1,  '->quarter is 1' );
    is( $dt->day_of_quarter, 32, '->day_of_quarter' );
    is( $dt->quarter_length, 91, '->quarter_length' );
}

{
    my $dt = DateTime::Calendar::Christian->new( year => 1996, month => 5, day => 1 );

    is( $dt->quarter,        2,  '->quarter is 2' );
    is( $dt->day_of_quarter, 31, '->day_of_quarter' );
    is( $dt->quarter_length, 91, '->quarter_length' );
}

{
    my $dt = DateTime::Calendar::Christian->new( year => 1996, month => 8, day => 1 );

    is( $dt->quarter,        3,  '->quarter is 3' );
    is( $dt->day_of_quarter, 32, '->day_of_quarter' );
    is( $dt->quarter_length, 92, '->quarter_length' );
}

{
    my $dt = DateTime::Calendar::Christian->new( year => 1996, month => 11, day => 1 );

    is( $dt->quarter,        4,  '->quarter is 4' );
    is( $dt->day_of_quarter, 32, '->day_of_quarter' );
    is( $dt->quarter_length, 92, '->quarter_length' );
}

{   # Lifted shamelessly from DateTime's t/07compare.t
    my $dt = DateTime::Calendar::Christian->now;
    ok(
        $dt->is_between( _add( $dt, -1 ), _add( $dt, 1 ) ),
        'is_between 1 minute before and 1 minute after'
    );
    ok(
        !$dt->is_between( _add( $dt, 1 ), _add( $dt, 2 ) ),
        'not is_between 1 minute after and 2 minutes after'
    );
    ok(
        !$dt->is_between( _add( $dt, 1 ), _add( $dt, -1 ) ),
        'not is_between 1 minute after and 1 minute before (wrong order for lower and upper)'
    );
    ok(
        !$dt->is_between( $dt, _add( $dt, 1 ) ),
        'not is_between same datetime and 1 minute after'
    );
    ok(
        !$dt->is_between( _add( $dt, -1 ), $dt ),
        'not is_between 1 minute before and same datetime'
    );
}
foreach my $info (
    [ 1500, 365, 0 ],	# 1500 is a leap year in the Julian calendar
    [ 1500, 366, 1 ],
    [ 1501, 365, 1 ],
    [ 1700, 365, 1 ],	# 1700 is not a leap year in the Gregorian calendar
    [ 1704, 365, 0 ],	# but 1704 is
    [ 1704, 366, 1 ],
) {
    my ( $year, $yday, $is_last ) = @{ $info };
    my $dt = DateTime::Calendar::Christian->from_day_of_year(
	year		=> $year,
	day_of_year	=> $yday,
    );
    # OK, I'm cheating by bundling all the is_last_day_* tests together,
    # but I think I have a meaningful test of each.
    cmp_ok $dt->is_last_day_of_month, '==', $is_last,
	sprintf '%04d-%03d (%s) %s the last day of the month',
	$year, $yday, $dt->calendar_name, $is_last ? 'is' : 'is not';
    cmp_ok $dt->is_last_day_of_quarter, '==', $is_last,
	sprintf '%04d-%03d (%s) %s the last day of the quarter',
	$year, $yday, $dt->calendar_name, $is_last ? 'is' : 'is not';
    cmp_ok $dt->is_last_day_of_year, '==', $is_last,
	sprintf '%04d-%03d (%s) %s the last day of the year',
	$year, $yday, $dt->calendar_name, $is_last ? 'is' : 'is not';
}

foreach my $info (
    [ 1500, 2, 29 ],	# 1500 is a leap year in the Julian calendar
    [ 1501, 2, 28 ],
    [ 1700, 2, 28 ],	# 1700 is not a leap year in the Gregorian calendar
    [ 1704, 2, 29 ],	# but 1704 is
) {
    my ( $year, $mon, $len ) = @{ $info };
    my $dt = DateTime::Calendar::Christian->new(
	year	=> $year,
	month	=> $mon,
	day	=> 1,
    );
    cmp_ok $dt->month_length, '==', $len,
    sprintf 'Month %04d-%02d (%s) is %d days long', $year, $mon,
    $dt->calendar_name, $len;
}

foreach my $info (
    [ 1200, 91 ],
    [ 1500, 91 ],
    [ 1501, 90 ],
    [ 1600, 91 ],
    [ 1601, 90 ],
    [ 1700, 90 ],
) {
    my ( $year, $len ) = @{ $info };
    my $dt = DateTime::Calendar::Christian->new(
	year	=> $year,
	month	=> 1,
	day	=> 1,
    );
    cmp_ok $dt->quarter_length( 1 ), '==', $len,
	sprintf 'Length of first quarter of %04d (%s) is %d days',
	$year, $dt->calendar_name, $len;
}

foreach my $info (
    [ 1500, '1500-01-01T00:00:00' ],
    [ 1600, '1600-01-01T00:00:00' ],
) {
    my ( $year, $str ) = @{ $info };
    my $dt = DateTime::Calendar::Christian->new(
	year	=> $year,
	month	=> 1,
	day	=> 1,
    );
    cmp_ok $dt->stringify, 'eq', $str,
	sprintf q<January 1 %04d (%s) stringifies by default to '%s'>,
	$year, $dt->calendar_name, $str;

    cmp_ok $dt->rfc3339, 'eq', $str,
	sprintf q<January 1 %04d (%s) per rfc3339 is '%s'>,
	$year, $dt->calendar_name, $str;

}

foreach my $info (
    [ 1200, 366 ],
    [ 1500, 366 ],
    [ 1501, 365 ],
    [ 1600, 366 ],
    [ 1601, 365 ],
    [ 1700, 365 ],
) {
    my ( $year, $len ) = @{ $info };
    my $dt = DateTime::Calendar::Christian->new(
	year	=> $year,
	month	=> 1,
	day	=> 1,
    );
    cmp_ok $dt->year_length, '==', $len,
	sprintf 'Length of year %04d (%s) is %d days',
	$year, $dt->calendar_name, $len;
}

done_testing;

sub _add {
    shift->clone->add( minutes => shift );
}

1;

# ex: set textwidth=72 :
