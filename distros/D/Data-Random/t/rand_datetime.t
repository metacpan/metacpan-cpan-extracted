use strict;
use warnings;
use Test::More;

use Data::Random qw( rand_datetime );
use Time::Piece;

my $today = localtime;

my $min_date = Time::Piece->strptime($today->ymd, "%Y-%m-%d");
my $max_date = $min_date->add_years(1);

my @tests = (
  {
    name => 'no args',
    args => {},
    min  => $today->ymd . ' ' . $today->hms,
    max  => $today->add_years(1)->ymd .' ' . $today->hms,
  },
  {
    name => 'min',
    args => {
      min => '1979-08-02 00:00:00',
    },
    min => '1979-08-02 00:00:00',
    max => '1980-08-02 23:59:59',
  },
  {
    name => 'min && max',
    args => {
      min => '2015-3-1 19:0:0',
      max => '2015-5-10 8:00:00',
    },
    min => '2015-03-01 19:00:00',
    max => '2015-05-10 08:00:00',
  },
  {
    name => 'min now',
    args => {
      min => 'now',
    },
    min => $today->ymd . ' ' . $today->hms,
    max => $today->add_years(1)->ymd . ' ' . $today->hms,
  },
  {
    name => 'max now',
    args => {
      min => '2014-07-11 4:00:00',
      max => 'now',
    },
    min => '2014-07-11 4:00:00',
    max => $today->ymd . ' ' . $today->hms,
  },
);

for my $test (@tests) {
  note "Running $test->{name}";

  # creating Time::Piece objects from 'min' and 'max' values.
  my $min_date = Time::Piece->strptime($test->{min},"%Y-%m-%d %H:%M:%S");
  my $max_date = Time::Piece->strptime($test->{max},"%Y-%m-%d %H:%M:%S");

  for ( 0..999 ) {
    my $rand_datetime = rand_datetime(%{$test->{args}});
    like(
      $rand_datetime,
      qr/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/,
      'rand_datetime format'
    );

    my $result   = Time::Piece->strptime($rand_datetime,  "%Y-%m-%d %H:%M:%S");
    cmp_ok($result, '>=', $min_date, 'rand_datetime not smaller than minimum');
    cmp_ok($result, '<=', $max_date, 'rand_datetime not bigger than maximum');
  }
}

done_testing;

