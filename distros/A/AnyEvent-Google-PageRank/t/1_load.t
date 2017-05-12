#!/usr/bin/env perl

use Test::More;
use strict;
BEGIN { use_ok('AnyEvent::Google::PageRank') };

my $rank = eval{ AnyEvent::Google::PageRank->new() };
ok(defined $rank, 'AnyEvent::Google::PageRank->new()');
isa_ok($rank, 'AnyEvent::Google::PageRank');

$rank = eval{ AnyEvent::Google::PageRank->new(timeout => 30, proxy => 'localhost:8080', host => 'rank5.google.com') };
ok(defined $rank, 'AnyEvent::Google::PageRank->new(%opts)');

$rank = eval{ AnyEvent::Google::PageRank->new(timeout => 30, proxy => 'localhost:8080', host => 'rank5.google.com', super => 18) };
ok(!defined $rank, 'AnyEvent::Google::PageRank->new(%bad_opts)');

done_testing();
