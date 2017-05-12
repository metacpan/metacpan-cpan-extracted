use strict;
use warnings;
use Test::More;

use Data::Random qw( rand_date );
use Time::Piece;

my $today = localtime;

my $min_date = Time::Piece->strptime($today->ymd, "%Y-%m-%d");
my $max_date = $min_date->add_years(1);

my @tests = (
  {
    name => 'no args',
    args => {},
    min  => $today->ymd,
    max  => $today->add_years(1)->ymd,
  },
  {
    name => 'min',
    args => {
      min => '1979-08-02',
    },
    min => '1979-08-02',
    max => '1980-08-02',
  },
  {
    name => 'min && max',
    args => {
      min => '2015-3-1',
      max => '2015-5-10',
    },
    min => '2015-03-01',
    max => '2015-05-10',
  },
  {
    name => 'min now',
    args => {
      min => 'now',
    },
    min => $today->ymd,
    max => $today->add_years(1)->ymd,
  },
  {
    name => 'max now',
    args => {
      min => '2014-07-11',
      max => 'now',
    },
    min => '2014-07-11',
    max => $today->ymd,
  },
);

for my $test (@tests) {
  note "Running $test->{name}";

  # creating Time::Piece objects from 'min' and 'max' values.
  my $min_date = Time::Piece->strptime($test->{min},"%Y-%m-%d");
  my $max_date = Time::Piece->strptime($test->{max},"%Y-%m-%d");

  for ( 0..999 ) {
    my $rand_date = rand_date(%{$test->{args}});
    note "Result: $rand_date";
    like($rand_date, qr/^\d{4}-\d{2}-\d{2}$/, 'rand_date format');

    my $result   = Time::Piece->strptime($rand_date,  "%Y-%m-%d");
    cmp_ok($result, '>=', $min_date, 'rand_date not smaller than minimum');
    cmp_ok($result, '<=', $max_date, 'rand_date not bigger than maximum');
  }
}

done_testing;

