#! /usr/bin/perl

use strict;
use warnings;
use Test::More 0.88;

require BenchmarkAnything::Config;

my $cfg1 = BenchmarkAnything::Config->new;
is($cfg1->{benchmarkanything}{storage}{backend}{sql}{dsn}, "dbi:SQLite:t/benchmarkanything.sqlite", "cfg 1");

my $cfg2;
{
    local $ENV{HARNESS_ACTIVE} = 0; # otherwise we would not interpret BENCHMARKANYTHING_CONFIGFILE
    local $ENV{BENCHMARKANYTHING_CONFIGFILE} = "t/benchmarkanything-2.cfg";
    $cfg2 = BenchmarkAnything::Config->new;
}
is($cfg2->{benchmarkanything}{storage}{backend}{sql}{dsn}, "dbi:SQLite:t/benchmarkanything-alternative.sqlite", "cfg 2");

my $cfg3 = BenchmarkAnything::Config->new(cfgfile => "t/benchmarkanything-3.cfg");
is($cfg3->{benchmarkanything}{storage}{backend}{sql}{dsn}, "dbi:SQLite:t/benchmarkanything-yet-another-alternative.sqlite", "cfg 3");

# Finish
done_testing;
