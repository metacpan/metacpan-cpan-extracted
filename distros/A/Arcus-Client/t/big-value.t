#!/bin/perl

use strict;
use warnings;
use Test::More;

use Arcus::Client;

use FindBin;
use lib "$FindBin::Bin";
use ArcusTestCommon;

if (not ArcusTestCommon->is_zk_port_opened()) {
  plan skip_all => "zk is not running...";
}

open(STDERR, '>', '/dev/null');

my $cache = ArcusTestCommon->create_client();
unless (ok($cache, "Check Arcus Client Is Created Appropriately")) {
  plan skip_all => "arcus client is not created appropriately...";
};

use constant THRESHOLD => 1024 * 1024 - 1024;

my $key         = 'big_value';
my $value       = 'x' x THRESHOLD;
my $small_value = 'x' x ( THRESHOLD - 2048 );
my $big_value   = 'x' x ( THRESHOLD + 2048 );

ok $cache->set( $key, $value ), 'Store value uncompressed';
is $cache->get($key), $value, 'Fetch';
ok !$cache->set( $key, $big_value ), 'Values greater than 1MB should be rejected by server';

my @res = $cache->set_multi(
  [ "$key-1", $small_value ],
  [ "$key-2", $big_value ],
  [ "$key-3", $small_value ]
);

is_deeply \@res, [ 1, undef, 1 ];
ok $cache->delete ("$key-1" );
ok $cache->delete( "$key-3" );
#ok $cache->delete_multi( "$key-1", "$key-3" );
done_testing;
