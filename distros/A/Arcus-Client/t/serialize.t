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

my $cache = ArcusTestCommon->create_client("perl-test:");
unless (ok($cache, "Check Arcus Client Is Created Appropriately")) {
  plan skip_all => "arcus client is not created appropriately...";
};

my $key  = "iek";
my $val = "ieky";
my @arr = ('i', 'e', 'k', 'y');
my %hash = ( i => 'a', e => 2, k => [ 'a', 1 ], y => { a => 1, b => [] } );

ok($cache->set($key, $val), "set scalar");
is($cache->get($key), $val, "get scalar");
ok($cache->prepend($key, "garbage"), "prepend garbage at scalar");
is($cache->get($key), "garbage".$val, "get scalar with garbage");
is_deeply($cache->get_multi($key), { $key => "garbage".$val }, "get scalar with garbage");

ok($cache->set($key, \@arr), "set array");
is_deeply($cache->get($key), \@arr, "get array");
is_deeply($cache->get_multi($key), { $key => \@arr }, 'get_multi array');
ok($cache->prepend($key, "garbage"), "prepend garbage at array");
is_deeply($cache->get($key), undef, "get array with garbage");
is_deeply($cache->get_multi($key), {}, "get_multi array with garbage");


ok($cache->set($key, \%hash), 'set hash');
is_deeply($cache->get($key), \%hash, 'get hash');
is_deeply($cache->get_multi($key), { $key => \%hash }, 'get_multi hash');
ok($cache->prepend($key, 'garbage'), 'prepend garbage at hash');
is($cache->get($key), undef, 'get hash with garbage');
is_deeply($cache->get_multi($key), {}, "get_multi hash with garbage");

ok($cache->delete($key), 'delete()');

%hash = ( a => 'a', b => 2, c => [ 'a', 1 ], d => { a => 1, b => [] } );
$key  = 'serialize';

ok $cache->set( $key => \%hash ), 'set()';
is_deeply $cache->get($key), \%hash, 'get()';
is_deeply $cache->get_multi($key), { $key => \%hash }, 'get_multi()';

subtest prepend => sub {
  ok $cache->prepend( $key => 'garbage' ), 'prepend()';
  is $cache->get($key), undef, 'get()';
  is_deeply $cache->get_multi($key), {}, 'get_multi()';
};

ok $cache->delete($key), 'delete()';

done_testing;
