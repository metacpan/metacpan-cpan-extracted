# - perl -
use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 8;
use Date::Holidays::NYSE;

{
  my $name = q{New Year's Day};

  ok(!Date::Holidays::NYSE::is_holiday(2024,8,19));

  my $holidays = Date::Holidays::NYSE::holidays(2024);
  #diag(Dumper $holidays);

  is(Date::Holidays::NYSE::is_holiday(2024,1,1), $name);
  ok(exists $holidays->{'0101'});
  is($holidays->{'0101'}, $name);
}

{
  my $name = q{New Year's Day};

  ok(!Date::Holidays::NYSE::is_nyse_holiday(2024,8,19));

  my $holidays = Date::Holidays::NYSE::nyse_holidays(2024);
  #diag(Dumper $holidays);

  is(Date::Holidays::NYSE::is_nyse_holiday(2024,1,1), $name);
  ok(exists $holidays->{'0101'});
  is($holidays->{'0101'}, $name);
}
