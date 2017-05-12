#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::Most;
use Test::FailWarnings;

use App::CatalystStarter::Bloated;

cmp_deeply(
    [App::CatalystStarter::Bloated::_fix_dbi_driver_case(qw/Pg pg pG PG/)],
    [("Pg")x4],
    "Pg case fix"
);

cmp_deeply(
    [App::CatalystStarter::Bloated::_fix_dbi_driver_case(qw/fooBAR FoObar/)],
    [qw/fooBAR FoObar/],
    "case fix on unknown driver"
);

note( "one input value only" );

is(
    App::CatalystStarter::Bloated::_fix_dbi_driver_case("pg"),
    "Pg",
    "one argument, pg"
);

done_testing;
