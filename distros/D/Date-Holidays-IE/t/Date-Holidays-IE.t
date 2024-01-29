# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Date-Holidays-IE.t'

#########################

use strict;
use warnings;

use Test::More;
use lib qw(lib);

use Date::Holidays::IE qw(holidays is_holiday);

use Data::Dumper;

# All EIRE holidays for 2023
my $holidays_2023 = holidays( year => 2023 );
is_deeply( $holidays_2023 => {
                              '0605' => 'June Holiday',
                              '1030' => 'October Holiday',
                              '0410' => 'Easter Monday',
                              '1226' => 'St. Stephen\'s Day',
                              '0101' => 'New Year\'s Day',
                              '0317' => 'Saint Patrick\'s Day',
                              '0807' => 'August Holiday',
                              '0206' => 'Saint Brigid\'s Day',
                              '0501' => 'May Day',
                              '1225' => 'Christmas Day'
                             },
           'Holidays for 2023 ok');

my $xmas_day1 = is_holiday(
                           year => 2023, month => 12, day => 25
                          );
is ($xmas_day1, 'Christmas Day', 'Christmas Day marked as holiday');

my $xmas_day2 = is_holiday( date => '2023-12-25' );
is ($xmas_day2, 'Christmas Day', 'Christmas Day marked as holiday');

my $justanother_day = is_holiday( date => '2023-12-28' );
is ($justanother_day, undef, 'Between xmas and new year need to book your own PTO');

my $newyears_day = is_holiday( date => '2023-1-1' );
is ($newyears_day, "New Year's Day", 'NYD is national holiday');


my $newyears_day_holiday = holidays( date => '2023-1-1' );
is_deeply ($newyears_day_holiday,
           {'0101' => 'New Year\'s Day' },
           'NYD is national holiday');

done_testing();
