#!perl
use strict;
use Test::More tests => 22;
use AnyEvent::XMPP::Util qw/from_xmpp_datetime to_xmpp_datetime to_xmpp_time
                           xmpp_datetime_as_timestamp/;

# to conversion
is (to_xmpp_time (1, 2, 3)          , '03:02:01'      , "basic to_xmpp_time");
is (to_xmpp_time (1, 2, 3, "Z")     , '03:02:01Z'     , "utc to_xmpp_time");
is (to_xmpp_time (1, 2, 3, "+01:10"), '03:02:01+01:10', "+01:10 to_xmpp_time");
is (to_xmpp_time (1, 2, 3, "+01:10", 0.123),
    '03:02:01.123+01:10'                              , "+01:10 with frac to_xmpp_time");

is (to_xmpp_datetime (23, 3, 4, 13, 5, 108, 'Z', 0.32),
    '2008-06-13T04:03:23.320Z',                         "to_xmpp_datetime");

# old format
my ($sec, $min, $hour, $mday, $mon, $year, $tz, $secfrac)
   = from_xmpp_datetime ("20070730T17:06:25");

is (1*$sec ,   25, "old format seconds");
is (1*$min ,    6, "old format minutes");
is (1*$hour,   17, "old format hours");
is (1*$mday,   30, "old format month day");
is (1*$mon ,    6, "old format month");
is (1*$year,  107, "old format year");
ok ((not defined $tz)     , "no tz defined");
ok ((not defined $secfrac), "no secfrac defined");

my $ts = xmpp_datetime_as_timestamp ("20070730T18:51:40-02:10");
is ($ts, '1185813700', "timestamp is UTC located");

# new format
($sec, $min, $hour, $mday, $mon, $year, $tz, $secfrac)
   = from_xmpp_datetime ("03:02:01.123+01:10");

is (1*$sec ,    1,       "new format seconds");
is (1*$min ,    2,       "new format minutes");
is (1*$hour,    3,       "new format hours");
is (1*$secfrac, '0.123', "new format secfrac");
ok ((not defined $mday),     "new format no mday defined");
ok ((not defined $mon) ,     "new format no mon defined");
ok ((not defined $year),     "new format no year defined");
is ($tz,        '+01:10',    "new format tz");
