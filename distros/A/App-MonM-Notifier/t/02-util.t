#!/usr/bin/perl -w
#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 02-util.t 60 2019-07-14 09:57:26Z abalama $
#
#########################################################################
use Test::More tests => 3;
use App::MonM::Notifier::Util;

# Check periods
{
  my $user_config_struct = {
    period => "7:00-19:00",
    channel => {
        foo => {
                period => "4:00-23:00",
            },
        bar => {
                period => "10:00-19:00",
                thu    => "7:45-14:25",
                sun    => "-",
                fri    => "0:0-1:0",
                wed    => "17:34-17:40",
        },
        baz => {},
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
