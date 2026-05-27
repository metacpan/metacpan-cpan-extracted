#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

plan skip_all => 'set RELEASE_TESTING=1 to run author tests'
    unless $ENV{RELEASE_TESTING};

# The top version entry in Changes must match $ClickHouse::Encoder::VERSION
# (and TCP's), so a release tarball never ships an undocumented version.

use lib 'lib';
require ClickHouse::Encoder;
my $mod_version = $ClickHouse::Encoder::VERSION;
ok(defined $mod_version && length $mod_version,
   "ClickHouse::Encoder::VERSION is set ($mod_version)");

open my $fh, '<', 'Changes' or do {
    plan skip_all => 'Changes file not found';
};
my $top;
while (my $line = <$fh>) {
    # First line that starts with a version-like token.
    if ($line =~ /^\s*(\d+\.\d+(?:[._]\d+)*)\s/) {
        $top = $1;
        last;
    }
}
close $fh;

ok(defined $top, 'found a version entry in Changes')
    or BAIL_OUT('Changes has no parseable version line');

is($top, $mod_version,
   "Changes top entry ($top) matches module VERSION ($mod_version)");

# TCP module shares the distribution version.
require ClickHouse::Encoder::TCP;
is($ClickHouse::Encoder::TCP::VERSION, $mod_version,
   'ClickHouse::Encoder::TCP::VERSION matches the main module');

done_testing();
