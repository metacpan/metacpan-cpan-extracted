#!/usr/bin/env perl
use strictures 2;
use Test2::V0;

use Curio::Guard;

my $g1_count = 0;
my $g1 = Curio::Guard->new(sub{ $g1_count++ });
is( $g1_count, 0, 'guard sub has not run' );
undef $g1;
is( $g1_count, 1, 'guard sub was run' );

done_testing;
