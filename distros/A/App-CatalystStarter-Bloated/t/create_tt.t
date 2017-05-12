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

goto_test_dir;

local %ARGV = test_argv( "--TT" => "HTML2" );

App::CatalystStarter::Bloated::_mk_app();
App::CatalystStarter::Bloated::_create_TT();

ok( -e App::CatalystStarter::Bloated::_catalyst_path( "V", "HTML2.pm" ),
    "create TT view" );

clean_cat_dir;

App::CatalystStarter::Bloated::_mk_app();
$ARGV{"--verbose"} = 1;
stdout_like sub { App::CatalystStarter::Bloated::_create_TT() },
    qr/\bcreated.*HTML2\.pm\b/,
    "verbose create";

done_testing
