# - perl -
use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 8;
use Date::Holidays::US qw{is_holiday};
use Date::Holidays::US qw{is_us_holiday};
use Date::Holidays::US qw{holidays};
use Date::Holidays::US qw{us_holidays};

{
  my $name = q{New Year's Day};

  ok(!is_holiday(2022,8,19));

  my $holidays = holidays(2022);
  #diag(Dumper $holidays);

  is(is_holiday(2022,1,1), $name);
  ok(exists $holidays->{'0101'});
  is($holidays->{'0101'}, $name);
}

{
  my $name = q{New Year's Day};

  ok(!is_us_holiday(2022,8,19));

  my $holidays = us_holidays(2022);
  #diag(Dumper $holidays);

  is(is_us_holiday(2022,1,1), $name);
  ok(exists $holidays->{'0101'});
  is($holidays->{'0101'}, $name);
}
