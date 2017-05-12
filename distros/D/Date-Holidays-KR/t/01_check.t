use strict;

BEGIN { $ENV{TZ} = 'Asia/Seoul' } 

use Date::Holidays::KR;
use Test::More;

my @tests = (
  [ 1984, 2, 2, '설날' ],
  [ 1984, 1, 1, '신정' ],
  [ 2012, 1, 23, '설날' ],
  [ 2012, 1, 22, '설앞날' ],
  [ 2012, 5, 28, '부처님오신날' ],
  [ 2012, 12, 25, '크리스마스' ],
  [ 2012, 1, 5, undef ],
  [ 2090, 1, 1, '신정' ],
);

for my $test (@tests) {
  my ($year, $month, $day, $holiday_name) = @{ $test };
  is(is_holiday($year, $month, $day), $holiday_name);
}

done_testing;
