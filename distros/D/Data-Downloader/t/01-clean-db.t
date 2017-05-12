#!/usr/bin/env perl

# Pragmas
use strict;
use warnings;

# Modules
use Data::Downloader::DB;
use FindBin qw/$Bin/;
use Test::More  tests => 2;
use t::lib::functions;


BAIL_OUT "Test harness is not active; use prove or ./Build test"
    unless($ENV{HARNESS_ACTIVE});

my $db = Data::Downloader::DB->new();

is($db->domain, 'test', 'in test domain') or BAIL_OUT "not in test domain";

ok(test_cleanup(undef, $db), "Remove old database");

1;

