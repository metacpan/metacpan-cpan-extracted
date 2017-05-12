use strict;
use warnings;

use Test::More tests => 17;
use DateTime;
use DateTime::Fiction::JRRTolkien::Shire;

# A very important day
my $shire = DateTime::Fiction::JRRTolkien::Shire->new(year => 1419,
						      month => 3,
						      day => 25,
						      hour => 10);

# 1-8
$shire->set(day => 28);
is($shire->day, 28);
is( $shire->day_of_week(), 5 );
$shire->set(holiday => 2);
is($shire->doy, 182);
$shire->set(month => 'Thrimidge',
	    year => 1420);
is($shire->month, 5);
is($shire->year, 1420);
$shire->set_holiday( 'Overlithe' );
is($shire->holiday, 4);
$shire->set(month => 2);
is($shire->month, 2);
cmp_ok( $shire->hour(), '==', 10, 'Ensure hour preserved so far' ); 

# 9-16
$shire->truncate(to => 'day');
is($shire->hour, 0);
$shire->truncate(to => 'month');
is($shire->day, 1);
is($shire->month, 2);
$shire->truncate( to => 'week' );
is( $shire->day(), 28 );
is( $shire->day_of_week(), 1 );
is( $shire->month(), 1 );
$shire->truncate(to => 'year');
is($shire->holiday, 1);
is($shire->year, 1420);

# 17
ok($shire->set_time_zone('floating'));
