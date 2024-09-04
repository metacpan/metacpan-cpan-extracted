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

use constant count => 100;

my $cache = ArcusTestCommon->create_client();
unless (ok($cache, "Check Arcus Client Is Created Appropriately")) {
  plan skip_all => "arcus client is not created appropriately...";
};

ok $cache->flush_all();

my $key  = 'commands';
my @keys = map "commands-$_", 1 .. count;

ok $cache->add( $key => 'foo' ), 'add';

# Delete/remove return whether they deleted anything.
ok $cache->delete($key),  'delete';
ok !$cache->remove($key), 'remove';

ok $cache->add( $key, 'v1', undef ), 'Add';
is $cache->get($key), 'v1', 'Fetch';

ok $cache->set( $key, 'v2', undef ), 'Set';
is $cache->get($key), 'v2', 'Fetch';

ok $cache->replace( $key, 'v3' ), 'Replace';
is $cache->get($key), 'v3', 'Fetch';

ok $cache->replace( $key, 0 ), 'replace with numeric';
ok $cache->incr($key),         'Incr';
ok $cache->get($key) == 1,     'Fetch';
ok $cache->incr( $key, 5 ),    'Incr';

ok !$cache->incr( 'no-such-key', 5 ), 'Incr no_such_key';
ok !$cache->incr( 'no-such-key', 5 ), 'Incr no_such_key returns defined value';

ok $cache->get($key) == 6,         'Fetch';
ok $cache->decr($key),             'Decr';
ok $cache->get($key) == 5,         'Fetch';
ok $cache->decr( $key, 2 ),        'Decr';
ok $cache->get($key) == 3,         'Fetch';
ok $cache->decr( $key, 100 ) == 0, 'Decr below zero';
ok $cache->decr( $key, 100 ),      'Decr below zero returns true value';
ok $cache->get($key) == 0,         'Fetch';

ok $cache->get_multi, 'get_multi() with empty list';

is_deeply { $cache->set_multi }, {}, 'list set_multi()';
my $href = $cache->set_multi();
is_deeply $href, {}, 'scalar set_multi()';

my @res = $cache->set_multi( map { [ $_, $_ ] } @keys );
is @res,                    count;
is grep( { not $_ } @res ), 0;
my $res = $cache->set_multi( map { [ $_, $_ ] } @keys );
is keys %$res,                      count;
is grep( { not $_ } values %$res ), 0;

my @extra_keys = @keys;
splice @extra_keys, rand( @extra_keys + 1 ), 0, "no_such_key-$_" for 1 .. count;

is_deeply $cache->get_multi(@extra_keys), { map { $_ => $_ } @keys };

subtest 'cas/gets/append/prepend' => sub {
  ok $cache->set( $key, 'value' ),      'Store';
  ok $cache->append( $key, '-append' ), 'Append';
  is $cache->get($key), 'value-append', 'Fetch';
  ok $cache->prepend( $key, 'prepend-' ), 'Prepend';
  is $cache->get($key), 'prepend-value-append', 'Fetch';

  $res = $cache->gets($key);
  ok $res, 'Gets';
  is @$res, 2, 'Gets result is an array of two elements';
  ok $res->[0], 'CAS opaque defined';
  is $res->[1], 'prepend-value-append', 'Match value';
  $res->[1] = 'new value';
  ok $cache->cas( $key,  @$res ), 'First update success';
  ok !$cache->cas( $key, @$res ), 'Second update failure';
  is $cache->get($key), 'new value', 'Fetch';
};

$cache->set( $key, 'value' );
$cache->set( $_,   'value' ) for @keys;

ok $cache->replace_multi( map { [ $_, 0 ] } @keys ), 'replace_multi to reset to numeric';
#$res = $cache->incr_multi( [ $keys[0], 2 ], [ $keys[1] ], @keys[ 2 .. $#keys ] );
#is values %$res,                     @keys;
#is grep( { $_ != 1 } values %$res ), 1;
#is $res->{ $keys[0] },               2;

ok $cache->delete($key);
#$res = $cache->delete_multi( $keys[0], $keys[1] );
#ok $res->{ $keys[0] } && $res->{ $keys[1] };
ok $cache->delete( $keys[0] );
ok $cache->delete( $keys[1] );

ok $cache->remove( $keys[2] );
for my $index (0..$#keys) {
  if ($index < 3) {
    ok !$cache->delete($keys[$index]);
  } else {
    ok $cache->delete($keys[$index]);
  }
}
#@res = $cache->delete_multi(@keys);
#is @res,                    count;
#is grep( { not $_ } @res ), 3;

ok(!$cache->can("incr_multi"));
ok(!$cache->can("decr_multi"));
ok(!$cache->can("delete_multi"));

done_testing;
