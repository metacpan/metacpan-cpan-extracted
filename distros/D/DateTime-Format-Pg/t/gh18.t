
use strict;
use Test::More;

use_ok('DateTime::Format::Pg');

my $inputs = [
  '20200115T00:00:13',
  '2020-01-15T00:00:13',
];

for my $input (@$inputs) {
  my $dt = DateTime::Format::Pg->parse_datetime($input);

  is $dt->year, 2020;
  is $dt->month, 1;
  is $dt->day, 15;
  is $dt->hour, 0;
  is $dt->minute, 0;
  is $dt->second, 13;
}

done_testing;

