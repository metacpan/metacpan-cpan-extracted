# - perl -
use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 8;
use Date::Holidays::US;

{
  my $name = q{New Year's Day};

  ok(!Date::Holidays::US::is_holiday(2022,8,19));

  my $holidays = Date::Holidays::US::holidays(2022);
  #diag(Dumper $holidays);

  is(Date::Holidays::US::is_holiday(2022,1,1), $name);
  ok(exists $holidays->{'0101'});
  is($holidays->{'0101'}, $name);
}

{
  my $name = q{New Year's Day};

  ok(!Date::Holidays::US::is_us_holiday(2022,8,19));

  my $holidays = Date::Holidays::US::us_holidays(2022);
  #diag(Dumper $holidays);

  is(Date::Holidays::US::is_us_holiday(2022,1,1), $name);
  ok(exists $holidays->{'0101'});
  is($holidays->{'0101'}, $name);
}
