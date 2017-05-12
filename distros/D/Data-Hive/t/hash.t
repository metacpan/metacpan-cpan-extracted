#!perl
use strict;
use warnings;

use Data::Hive;
use Data::Hive::Store::Hash;

use Data::Hive::Test;

use Test::More 0.88;

use Try::Tiny;

sub exception (&) {
  my ($code) = @_;

  return try { $code->(); return } catch { return $_ };
}

Data::Hive::Test->test_new_hive(
  'basic hash store',
  { store => Data::Hive::Store::Hash->new },
);

for my $class (qw(
  Hash
  +Data::Hive::Store::Hash
  =Data::Hive::Store::Hash
)) {
  my $hive = Data::Hive->NEW({ store_class => $class });

  isa_ok($hive->STORE, 'Data::Hive::Store::Hash', "store from $class");
}

my $hive = Data::Hive->NEW({
  store_class => 'Hash',
});

my $tmp;

isa_ok($hive,      'Data::Hive', 'top-level hive');

isa_ok($hive->foo, 'Data::Hive', '"foo" subhive');

$hive->foo->SET(1);

is_deeply(
  $hive->STORE->hash_store,
  { foo => 1 },
  'changes made to store',
);

$hive->bar->baz->GET;

is_deeply(
  $hive->STORE->hash_store,
  { foo => 1 },
  'did not autovivify'
);

$hive->baz->quux->SET(2);

is_deeply(
  $hive->STORE->hash_store,
  {
    foo => 1,
    'baz.quux' => 2,
  },
  'deep set',
);

is(
  $hive->foo->GET,
  1,
  "get the 1 from ->foo",
);

is(
  $hive->foo->bar->GET,
  undef,
  "find nothing at ->foo->bar",
);

$hive->foo->bar->SET(3);

is(
  $hive->foo->bar->GET,
  3,
  "wrote and retrieved 3 from ->foo->bar",
);

ok ! $hive->not->EXISTS, "non-existent key doesn't EXISTS";
ok   $hive->foo->EXISTS, "existing key does EXISTS";

$hive->baz->quux->frotz->SET(4);

is_deeply(
  $hive->STORE->hash_store,
  {
    foo => 1,
    'foo.bar' => 3,
    'baz.quux' => 2,
    'baz.quux.frotz' => 4,
  },
  "deep delete"
);

my $quux = $hive->baz->quux;
is($quux->GET, 2, "get from saved leaf");
is($quux->DELETE, 2, "delete returned old value");
is($quux->GET, undef, "after deletion, hive has no value");

is_deeply(
  $hive->STORE->hash_store,
  {
    foo => 1,
    'foo.bar' => 3,
    'baz.quux.frotz' => 4,
  },
  "deep delete"
);

my $frotz = $hive->baz->quux->frotz;
is($frotz->GET, 4, "get from saved leaf");
is($frotz->DELETE, 4, "delete returned old value");
is($frotz->GET, undef, "after deletion, hive has no value");

is_deeply(
  $hive->STORE->hash_store,
  {
    foo => 1,
    'foo.bar' => 3,
  },
  "deep delete: after a hive had no keys, it is deleted, too"
);

{
  my $hive  = Data::Hive->NEW({
    store_class => 'Hash',
  });

  $hive->HIVE('and/or')->SET(1);
  $hive->foo->bar->SET(4);
  $hive->foo->bar->baz->SET(5);
  $hive->foo->quux->baz->SET(6);

  is_deeply(
    [ sort $hive->KEYS ],
    [ qw(and/or foo) ],
    "get the top level KEYS",
  );

  is_deeply(
    [ sort $hive->foo->KEYS ],
    [ qw(bar quux) ],
    "get the KEYS under foo",
  );

  is_deeply(
    [ sort $hive->foo->bar->KEYS ],
    [ qw(baz) ],
    "get the KEYS under foo/bar",
  );

  like(
    exception { $hive->HIVE('not.legal')->GET },
    qr/illegal.+path part/,
    "we can't use the delimiter in a path part with strict packer",
  );
}

done_testing;
