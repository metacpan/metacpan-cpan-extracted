#!/usr/bin/perl -w
#########################################################################
#
# Sergey Lepenkov (Serz Minus), <abalama@cpan.org>
#
# Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 04-util.t 42 2017-11-30 12:21:53Z abalama $
#
#########################################################################
use Test::More tests => 17;
use lib qw(inc);
use FakeCTK;
use App::MonM::Notifier::Util;
use App::MonM::Notifier::Const;

ok(defined tz_diff(time),'tz_diff()');
note sprintf("TimeZone diff: %s", tz_diff(time));

# Expires
is(getExpireOffset("+1d"), 86400, "1 day");
is(getExpireOffset("-3m"), -180, "-3 min.");

# IPv4
ok(is_ipv4("127.0.0.1"), "Local IP");
ok(!is_ipv4("127.0.0.256"), "Bad IP");

# ISO 8601
{
  my $ts = "2017-11-28T10:12:14Z";
  ok(is_iso8601($ts), "ISO 8601 value");

  my $tm = iso2time( $ts );
  is($ts, time2iso($tm), "ISO to Time and Time to ISO");
}

# Levels
{
  ok(checkLevel( "error",  LVL_ERROR), "ERROR=ERROR");
  ok(!checkLevel( "crit",  LVL_ERROR), "CRIT!=ERROR");
  ok(!checkLevel( "none",   LVL_ERROR), "none!=ERROR");
  ok(checkLevel( "debug",  LVL_ERROR), "DEBUG=ERROR");
  ok(checkLevel( "error,crit",  LVL_ERROR), "ERROR,CRIT=ERROR");
  ok(!checkLevel( "info,warning,alert",  LVL_ERROR), "INFO,WARNING,ALERT,CRIT!=ERROR");
  ok(!checkLevel( undef,  LVL_ERROR), "undef!=ERROR");
}

# Check periods
{
  my $user_config_struct = {
    period => "7:00-19:00",
    channel => {
        foo => {
                enable => 1,
                period => "4:00-23:00",
            },
        bar => {
                enable => 1,
                period => "10:00-19:00",
                thu    => "7:45-14:25",
                sun    => "-",
                fri    => "0:0-1:0",
                wed    => "17:34-17:40",
        },
        baz => {
                enable => 0,
            },
    }
  };
  my %periods = getPeriods( $user_config_struct );
  is(scalar(keys %periods), 7, "7 days on periods");
  %periods = getPeriods( $user_config_struct, "foo" );
  is(scalar(keys %periods), 7, "7 days on periods for foo");
  %periods = getPeriods( $user_config_struct, "baz" );
  is(scalar(keys %periods), 0, "0 days on periods for baz");
}
1;
