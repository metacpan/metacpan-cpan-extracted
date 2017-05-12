# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

BEGIN { $^W = 1 }

use Test::More tests => 30;
BEGIN { use_ok('DateTime::Calendar::Julian') };

#########################

my $d = DateTime::Calendar::Julian->new( year => 1582, month => 10, day => 5, time_zone => 'floating');
ok($d, 'creation of date');
is(($d->utc_rd_values)[0], 2299160-1721424, 'rata die');

use DateTime;

foreach $date (
                # Julian date , Gregorian   , diff
                [ '1582/10/05', '1582/10/15', 10 ], # Jul => Greg reform date
                [ '1752/09/03', '1752/09/14', 11 ], # English reform date
                [ '1900/02/29', '1900/03/13', 12 ], # Julian leap year
                [ '1918/02/01', '1918/02/14', 13 ], # Russian reform date
                [ '0000/01/03', '0000/01/01', -2 ], # 1 BC
                ['-4712/01/01','-4713/11/24',-38 ], # Julian Day 0
              ) {
    my ($y, $m, $day) = split '/', $date->[0];
    # time_zone to work around a bug(?) in early DateTime versions
    my $d = DateTime::Calendar::Julian->new(year      => $y,
                                            month     => $m,
                                            day       => $day,
                                            time_zone => 'floating' );
    my $dt = DateTime->from_object( object => $d );
    is($dt->ymd('/'), $date->[1], "converting $date->[0] to Gregorian");
    $d = DateTime::Calendar::Julian->from_object( object => $dt );

    is($d->ymd('/'), $date->[0], "converting $date->[1] to Julian");

    is($d->gregorian_deviation, $date->[2], "gregorian dev. on $date->[0]");
}

$d = DateTime::Calendar::Julian->new(year => 2003);
ok(!($d->is_leap_year), 'non-leap year');

$d = DateTime::Calendar::Julian->new(year => 2004);
ok($d->is_leap_year, 'ordinary leap year');

$d = DateTime::Calendar::Julian->new(year => 2000);
ok($d->is_leap_year, 'leap year (multiple of 400)');

$d = DateTime::Calendar::Julian->new(year => 1900);
ok($d->is_leap_year, 'leap year (multiple of 100)');

$d = DateTime::Calendar::Julian->new( year => 1900, month => 2, day => 29, time_zone => 'floating');
is($d->ymd, '1900-02-29', 'leap day 1900-02-29 exists');

$d = DateTime::Calendar::Julian->last_day_of_month( year => 1900, month => 2, time_zone => 'floating');
is($d->ymd, '1900-02-29', 'leap day 1900 is last of the month');

SKIP: {
    skip 'epoch not UNIX', 2 unless gmtime(0) eq 'Thu Jan  1 00:00:00 1970';
    $d = DateTime::Calendar::Julian->from_epoch( epoch => 0 );
    is( $d->epoch, 0, 'epoch 0' );
    is( $d->ymd, '1969-12-19', 'epoch is correct' );
}

$d = DateTime::Calendar::Julian->new( year => 1900, month => 10, day => 1, time_zone => 'floating');
$d->add( years => 1 );
is($d->ymd, '1901-10-01', 'adding a year');
