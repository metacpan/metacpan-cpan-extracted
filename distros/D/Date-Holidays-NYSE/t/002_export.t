# - perl -
use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 8;
use Date::Holidays::NYSE qw{is_holiday};
use Date::Holidays::NYSE qw{is_nyse_holiday};
use Date::Holidays::NYSE qw{holidays};
use Date::Holidays::NYSE qw{nyse_holidays};

{
  my $name = q{New Year's Day};

  ok(!is_holiday(2024,8,19));

  my $holidays = holidays(2024);
  #diag(Dumper $holidays);

  is(is_holiday(2024,1,1), $name);
  ok(exists $holidays->{'0101'});
  is($holidays->{'0101'}, $name);
}

{
  my $name = q{New Year's Day};

  ok(!is_nyse_holiday(2024,8,19));

  my $holidays = nyse_holidays(2024);
  #diag(Dumper $holidays);

  is(is_nyse_holiday(2024,1,1), $name);
  ok(exists $holidays->{'0101'});
  is($holidays->{'0101'}, $name);
}
