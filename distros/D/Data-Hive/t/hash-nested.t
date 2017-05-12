#!perl
use strict;
use warnings;

use Data::Hive;
use Data::Hive::Store::Hash::Nested;

use Data::Hive::Test;

use Test::More 0.88;

Data::Hive::Test->test_new_hive(
  'basic hash store',
  { store => Data::Hive::Store::Hash::Nested->new },
);

for my $class (qw(
  Hash::Nested
  +Data::Hive::Store::Hash::Nested
  =Data::Hive::Store::Hash::Nested
)) {
  my $hive = Data::Hive->NEW({ store_class => $class });

  isa_ok($hive->STORE, 'Data::Hive::Store::Hash::Nested', "store from $class");
}

my $hive = Data::Hive->NEW({
  store_class => 'Hash::Nested',
});

my $tmp;

isa_ok($hive,      'Data::Hive', 'top-level hive');

isa_ok($hive->foo, 'Data::Hive', '"foo" subhive');

$hive->foo->SET(1);

is_deeply(
  $hive->STORE->hash_store,
  { foo => { '' => 1 } },
  'changes made to store',
);

$hive->bar->baz->GET;

is_deeply(
  $hive->STORE->hash_store,
  { foo => { '' => 1 } },
  'did not autovivify'
);

$hive->baz->quux->SET(2);

is_deeply(
  $hive->STORE->hash_store,
  {
    foo => { '' => 1 },
    baz => { quux => { '' => 2 } },
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
    foo => { '' => 1, bar => { '' => 3 } },
    baz => { quux => { '' => 2, frotz => { '' => 4 } } },
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
    foo => { '' => 1, bar => { '' => 3 } },
    baz => { quux => { frotz => { '' => 4 } } },
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
    foo => { '' => 1, bar => { '' => 3 } },
  },
  "deep delete: after a hive had no keys, it is deleted, too"
);

{
  my $hive  = Data::Hive->NEW({
    store_class => 'Hash::Nested',
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
}

subtest 'start with existing old-style hash' => sub {
  my $hive  = Data::Hive->NEW({
    store_class => 'Hash::Nested',
    store_args  => [ {
      to_get    => { bar => 10 },
      to_exists => { bar => 10 },
      to_delete => { bar => { baz => 10, quux => 20 } },
      to_skip   => { bar => { baz => 10, quux => 20 } },
      to_keys   => { bar => { baz => 10, quux => 20 } },
    } ],
  });

  is($hive->to_get->bar->GET, 10, 'we can GET from old-style hash stores');

  is_deeply(
    $hive->STORE->hash_store->{to_get},
    { bar => { '' => 10 } },
    "...and we auto-upgrade them in place",
  );

  ok($hive->to_exists->bar->EXISTS, 'we can EXISTS old-style hash stores');

  is_deeply(
    $hive->STORE->hash_store->{to_exists},
    { bar => { '' => 10 } },
    "...and we auto-upgrade them in place",
  );

  is(
    $hive->to_delete->bar->baz->DELETE,
    10,
    'we can DELETE from old-style hash stores'
  );

  ok(
    ! $hive->to_delete->bar->baz->EXISTS,
    '...and the DELETE is effective',
  );

  is_deeply(
    $hive->STORE->hash_store->{to_delete},
    { bar => { quux => 20 } },
    "...and we auto-upgrade them in place",
  );

  is(
    $hive->to_skip->bar->baz->missing->whatever->DELETE,
    undef,
    "we can (fake) delete from a element past old-style non-ref",
  );

  is_deeply(
    $hive->STORE->hash_store->{to_skip}{bar}{baz},
    { '' => 10 },
    "...and we auto-upgrade them in place",
  );

  is_deeply(
    [ sort $hive->to_keys->bar->KEYS ],
    [ qw(baz quux) ],
    "we can get KEYS where the keys hold old-style scalar",
  );

  is_deeply(
    [ sort $hive->to_keys->bar->baz->KEYS ],
    [ ],
    "we can get KEYS (empty) of a non-ref leaf",
  );

  is_deeply(
    $hive->STORE->hash_store->{to_keys}{bar}{baz},
    { '' => 10 },
    "...and we auto-upgrade them in place",
  );
};

done_testing;
