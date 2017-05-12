#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::Most;
use Test::FailWarnings;
use Test::Output;

use lib 't/lib';
use TestUtils;

plan skip_all => "catalyst.pl not available" unless system_has_catalyst;

use_ok "App::CatalystStarter::Bloated", ":test";

local %ARGV = test_argv( "--JSON" => "JSON2" );

goto_test_dir;

App::CatalystStarter::Bloated::_mk_app();
App::CatalystStarter::Bloated::_create_JSON();

ok( -e App::CatalystStarter::Bloated::_catalyst_path( "V", "JSON2.pm" ),
    "create JSON view" );

App::CatalystStarter::Bloated::_mk_app();
$ARGV{"--verbose"} = 1;
stdout_like sub { App::CatalystStarter::Bloated::_create_JSON() },
    qr/\bcreated.*JSON2\.pm\b/,
    "verbose create";

done_testing;
