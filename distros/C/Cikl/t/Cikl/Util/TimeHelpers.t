package TestsFor::Cikl::Util::TimeHelpers;
use base qw(Test::Class);
use strict;
use warnings;
use Test::More;
use Test::Deep;
use DateTime;
use Cikl::Util::TimeHelpers qw/normalize_timestamp create_strptime_parser/;

use constant FAKE_NOW => DateTime->new(
  year       => 2012,
  month      => 11,
  day        => 7,
  hour       => 14,
  minute     => 06,
  second     => 07,
  time_zone  => 'UTC',
);

use constant FAKE_NOW_EPOCH => (DateTime->new(
  year       => 2012,
  month      => 11,
  day        => 7,
  hour       => 14,
  minute     => 06,
  second     => 07,
  time_zone  => 'UTC',
)->epoch());

sub normalizes_properly {
  my $name = shift;
  my $val = shift;
  my $expected = shift;
  subtest $name => sub {
    my $ret = normalize_timestamp($val);
    like($ret, qr/^\d{1,10}$/);
    is($ret, $expected, "is the expected epoch value");
  };
}

sub returns_now {
  my $name = shift;
  my $val = shift;
  subtest $name => sub {
    my $ret = normalize_timestamp($val, FAKE_NOW_EPOCH);
    like($ret, qr/^\d{10}$/);
    is($ret, FAKE_NOW_EPOCH, "fails to parse and returns default value (now)");
  };
}

sub test_normalize_timestamp : Test(13) {
  my $self = shift;
  my $dt = DateTime->new(
      year       => 2013,
      month      => 12,
      day        => 9,
      hour       => 12,
      minute     => 53,
      second     => 27,
      time_zone  => 'UTC',
  );
  my $epoch = $dt->epoch();

  normalizes_properly("a DateTime object", $dt, $epoch);
  normalizes_properly("an epoch", $epoch, $epoch);

  normalizes_properly("an iso8601 string with Z (yyyy-mm-ddThh:mm:ssZ)", 
    $dt->iso8601() . "Z", $epoch);

  normalizes_properly("an iso8601 string (yyyy-mm-ddThh:mm:ss)", 
    "2013-12-09T12:53:27", $epoch);

  normalizes_properly("a date time string with no separators plus timezone (yyyymmddhhmmssZZZ)", 
    $dt->ymd("") . $dt->hms('') . "UTC", $epoch);

  normalizes_properly("an 8 digit date time string of format (yyyymmdd)", 
    "20131209", 
    DateTime->new(
      year       => 2013,
      month      => 12,
      day        => 9,
      hour       => 0,
      minute     => 0,
      second     => 0,
      time_zone  => 'UTC',
    )->epoch()
);

  returns_now("an 8 digit date time with an invalid month", 
    "20131309");

  returns_now("an 8 digit date time with an invalid day", 
    "20131232");

  returns_now("a nine-digit number", "123456789");

  returns_now("a seven-digit number", "1234567");

  normalizes_properly("Mon, 21 Nov 94 13:55:19 UTC", 
    "Mon, 21 Nov 94 13:55:19 UTC", 
    DateTime->new(
      year       => 1994,
      month      => 11,
      day        => 21,
      hour       => 13,
      minute     => 55,
      second     => 19,
      time_zone  => 'UTC',
    )->epoch()
);

  normalizes_properly("Mon, 21 Nov 94 13:55:19 UTC", 
    "Mon,_21_Nov_94_13:55:19_UTC",
    DateTime->new(
      year       => 1994,
      month      => 11,
      day        => 21,
      hour       => 13,
      minute     => 55,
      second     => 19,
      time_zone  => 'UTC',
  )->epoch());

  is(normalize_timestamp("asdfasdf"), undef, "returns undef for things it can't parse");
}

sub test_parse_timestamp : Test(1) {
  my $self = shift;
  my $parser = create_strptime_parser("%y/%m/%d_%H:%M", "UTC");
  my $ret = $parser->("2013/10/09_13:48");
  is($ret, 1381326480, "Parses using a pattern");
}

Test::Class->runtests;

