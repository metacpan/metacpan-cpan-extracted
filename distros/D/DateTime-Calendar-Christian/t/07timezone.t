use 5.008004;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();
use DateTime::Calendar::Christian;

#########################

my ($rd, $d);

$rd = DateTime->new( year  => 1752,
                     month => 9,
                     day   => 14 );
$d = DateTime::Calendar::Christian->new( year  => 1752,
                                         month => 9,
                                         day   => 2,
                                         hour  => 22,
                                         reform_date => $rd,
                                         time_zone => 'America/Chicago' );
ok( $d->is_julian, 'Julian date in America' );
is( $d->ymd, '1752-09-02', 'Correct Julian date' );

$d->set_time_zone( 'UTC' );
ok( $d->is_gregorian, 'Gregorian date in England' );
is( $d->ymd, '1752-09-14', 'Correct Gregorian date' );

$d->set_time_zone( 'America/Chicago' );
ok( $d->is_julian, 'And back...' );
is( $d->ymd, '1752-09-02', 'Correct Julian date again' );

done_testing;

# ex: set textwidth=72 :
