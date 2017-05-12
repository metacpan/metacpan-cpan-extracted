#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use TestUtils;

use_ok("Parse::BACKPAN::Packages");

my $p = new_pbp();

my $cache = $p->cache;
is $cache->directory, cache_dir();
ok !$p->update;
ok $p->releases_only_from_authors;

done_testing;
