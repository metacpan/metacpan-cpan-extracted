use strict;
use warnings;

use Test::More tests => 8;
use DateTime::BusinessHours;
use DateTime;

# Date format used is US: YYYY-MM-DD

my $holidays = ['2013-11-28', '2013-11-29'];
my $d1 = DateTime->new( year => 2013, month => 11, day => 25 );
my $d2 = DateTime->new( year => 2013, month => 12, day => 3 );

my $t = DateTime::BusinessHours->new( datetime1 => $d1, datetime2 => $d2, holidays => $holidays );
is( $t->getdays,  4, 'getdays with holidays' );
is( $t->gethours, 32, 'gethours with holidays' );

# holiday file defined 2013-11-11 and 2013-11-10 a holiday (2013-11-10 is a sun)
$d1 = DateTime->new( year => 2013, month => 11, day => 10 );
$d2 = DateTime->new( year => 2013, month => 11, day => 12 );
$t = DateTime::BusinessHours->new( datetime1 => $d1, datetime2 => $d2, holidayfile => 't/var/holidayfile.txt' );
is ($t->getdays, 0, 'getdays with holiday file, no working hours');
is ($t->gethours, 0, 'gethours with holiday file, no working hours');

# holiday with working hours
$d1 = DateTime->new( year => 2013, month => 11, day => 10 );
$d2 = DateTime->new( year => 2013, month => 11, day => 13 );
$t = DateTime::BusinessHours->new( datetime1 => $d1, datetime2 => $d2, holidayfile => 't/var/holidayfile.txt' );
is ($t->getdays, 1, 'getdays with holiday file, with working hours');
is ($t->gethours, 8, 'gethours with holiday file, with working hours');

# holidayfile and holiday specified
$d1 = DateTime->new( year => 2013, month => 11, day => 10 );
$d2 = DateTime->new( year => 2013, month => 12, day => 1 );
$t = DateTime::BusinessHours->new( datetime1 => $d1, datetime2 => $d2, holidays => $holidays, holidayfile => 't/var/holidayfile.txt' );
is ($t->getdays, , 12, 'getdays with holiday file and holidays specified');
is ($t->gethours, 12 * 8, 'gethours with holiday file and holidays specified');
