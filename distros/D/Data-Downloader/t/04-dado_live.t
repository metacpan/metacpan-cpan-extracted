#!/usr/bin/env perl

# Pragmas
use strict;
use warnings;

# Modules
use File::Basename qw/dirname/;
use File::Path;
use FindBin qw/$Bin/;
use Test::More;
use t::lib::functions;


my $LIVE_TESTS
    = ($ENV{DATA_DOWNLOADER_LIVE_TESTS} || $ENV{DD_LIVE_TESTS}) ? 1 : 0;

plan skip_all => "Define DATA_DOWNLOADER_LIVE_TESTS to run live tests"
    unless($LIVE_TESTS);
plan qw/no_plan/;

BAIL_OUT "Test harness is not active; use prove or ./Build test"
    unless($ENV{HARNESS_ACTIVE});

set_path();

my $test_dir = scratch_dir();
rmtree($test_dir, { keep_root => 1, safe => 1 });

my $config_file = t_copy("$Bin/../etc/omi.yml", '/tmp/dado/omi', $test_dir);

ok_system("dado config init --file $config_file");

ok_system("dado feeds refresh --archiveset 10003 --esdt OMTO3 --count 10"
	  . " --startproductiontime 2008-10-10");

ok_system("dado feeds refresh --archiveset 10003 --esdt OMTO3 --count 10"
	  . " --startproductiontime 2008-10-10 --download 1");

# ok_system("dado file download --repository omi --md5 a46cee6a6d8df570b0ca977b9e8c3097 --filename OMI-Aura_L2-OMTO3_2007m0220t0052-o13831_v002-2007m0220t221310.he5");

ok(test_cleanup($test_dir), "Test clean up");

ok unlink $config_file, 'cleanup';

1;

