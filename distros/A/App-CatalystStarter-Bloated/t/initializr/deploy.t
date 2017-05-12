#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::Most;
use Test::FailWarnings;
use Path::Tiny;

use Test::File::ShareDir
    -share => {
        -module => { "App::CatalystStarter::Bloated::Initializr" => 'share' },
    };

use_ok "App::CatalystStarter::Bloated::Initializr";

lives_ok {App::CatalystStarter::Bloated::Initializr::_initialize_from_cache()}
    "zip fetched from cache";

my $d = Path::Tiny->tempdir;

App::CatalystStarter::Bloated::Initializr::deploy($d);

ok( -f path($d,"wrapper.tt2"), "wrapper.tt2 found after extract" );

done_testing;
