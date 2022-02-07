use 5.008004;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();
use DateTime::Calendar::Christian;

#########################

my ($d, $d2);

$d = DateTime::Calendar::Christian->new( year  => 1582,
                                         month => 10,
                                         day   => 4,
                                         hour  => 22 );

$d2 = $d->clone;
$d2->add( hours => 3 );
is( $d2->datetime, '1582-10-15T01:00:00', 'adding hours around calendar change' );
$d2->subtract( hours => 3 );
is( $d2->datetime, '1582-10-04J22:00:00', 'subtracting hours around calendar change' );

$d2 = $d->clone;
$d2->add( days => 3 );
is( $d2->ymd, '1582-10-17', 'adding days around calendar change' );
$d2->subtract( days => 3 );
is( $d2->ymd, '1582-10-04', 'subtracting days around calendar change' );

$d2 = $d->clone;
$d2->add( months => 3 );
is( $d2->ymd, '1583-01-14', 'adding months around calendar change' );
$d2->subtract( months => 3 );
is( $d2->ymd, '1582-10-04', 'subtracting months around calendar change' );

$d2 = $d->clone;
$d2->add( years => 3 );
is( $d2->ymd, '1585-10-14', 'adding years around calendar change' );
$d2->subtract( years => 3 );
is( $d2->ymd, '1582-10-04', 'subtracting years around calendar change' );

$d2 = $d->clone;
$d2->add( years => 300 );
is( $d2->ymd, '1882-10-14', 'adding centuries around calendar change' );
$d2->subtract( years => 300 );
is( $d2->ymd, '1582-10-04', 'subtracting centuries around calendar change' );

$d = DateTime::Calendar::Christian->new( year  => 1285,
                                         month => 1,
                                         day   => 1 );

$d->add( years => 300 );
is( $d->ymd, '1585-01-11', 'adding centuries around calendar change' );

$d->subtract( years => 300 );
is( $d->ymd, '1285-01-01', 'subtracting centuries around calendar change' );

$d = DateTime::Calendar::Christian->new(
        year => 1582, month => 10, day => 30 );
$d2 = DateTime::Calendar::Christian->new(
        year => 1582, month => 10, day => 1 );

my $dur = $d - $d2;
isa_ok( $dur, 'DateTime::Duration' );
is( $dur->delta_days, 19, 'datetime - datetime' );

TODO: {
    # NOTE not simply local $TODO = ... because this code actually
    # throws an execption.
    todo_skip 'mixed math (with DateTime objects) not implemented', 2;
    $d = DateTime->new( year => 1582, month => 10, day => 30 );
    $dur = $d2->subtract_datetime($d);
    isa_ok( $dur, 'DateTime::Duration' );
    is( $dur->delta_days, 19, 'subtracting DateTime object' );
}

##############################################
# Some historical examples

# George Washington's birthday

$d = DateTime::Calendar::Christian->new(
                       year  => 1732,
                       month => 2,
                       day   => 11,
                       reform_date => 'uk' );

$d2 = $d->clone;
$d2->add( years => 60 );
is( $d2->ymd, '1792-02-22', "Washington's 60th birthday" );
$d2 = $d->clone;
$d2->add( years => 100 );
is( $d2->ymd, '1832-02-22', "Washington's 100th birthday" );
# (This is actually 1832-02-10 Julian!)

$d2 = $d->clone->add( years => 200 );
is( $d2->ymd, '1932-02-22', "Washington's 200th birthday" );

# George II's birthday (see Ben Franklin's Poor Richard's Almanac for
# November 1753, http://www.gettysburg.edu/~tshannon/his341/pra53nov.htm)

$d = DateTime::Calendar::Christian->new(
                       year  => 1683,
                       month => 10,
                       day   => 30,
                       reform_date => 'uk' );

$d2 = $d->add( years => 70 );
is( $d->ymd, '1753-11-10', "George II's 70th birthday" );

# Russian revolution (october revolution)

$d = DateTime::Calendar::Christian->new(
                       year  => 1917,
                       month => 10,
                       day   => 25,
                       reform_date => 'russia' );

$d2 = $d->add( years => 86 );
is( $d->ymd, '2003-11-07', 'Russian revolution' );

{
    note <<'EOD';

RT 140734 - Christian Carey
EOD

    my $christian = DateTime::Calendar::Christian->new(
	year	=> 1582,
	month	=> 3,
	day	=> 1,
    )->add( days => 43_100 );

    is $christian->ymd, '1700-03-12',
	'1582-03-01 (Julian) plus 43,100 days is 1700_03_12 (Gregorian)';

    # Ensure that we round-trip.
    $christian->subtract( days => 43_100 );
    is $christian->ymd, '1582-03-01',
	'1700-03-12 (Gregorian) minus 43,100 days is 1582_03_01 (Julian)';
}

done_testing;

# ex: set textwidth=72 :
