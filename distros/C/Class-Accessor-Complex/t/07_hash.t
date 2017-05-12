#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 17;

package Foo;
use parent 'Class::Accessor::Complex';
__PACKAGE__->mk_new->mk_hash_accessors(qw(a_hash));

package main;
can_ok(
    'Foo', qw(
      a_hash a_hash_clear a_hash_keys a_hash_values a_hash_exists a_hash_delete a_hash_count
      )
);
is_deeply([ Foo->new->a_hash_keys ], [], 'empty to begin with');
my $o1 = Foo->new;
is($o1->a_hash_count, 0, 'count returns 0 after creation');
$o1->a_hash(a => 1, b => 2);
my %o1 = $o1->a_hash;
is_deeply(\%o1, { a => 1, b => 2 }, 'return hash in list context');
$o1->a_hash(a => 23, c => 4);
is_deeply({ $o1->a_hash }, { a => 23, b => 2, c => 4 }, 'append/overwrite');
is_deeply([ sort $o1->a_hash_keys ], [qw/a b c/], 'keys');
is_deeply([ sort { $a <=> $b } $o1->a_hash_values ], [qw/2 4 23/], 'value');
ok($o1->a_hash_exists('b'),  'exists() with an existing key');
ok(!$o1->exists_a_hash('f'), 'exists() with a non-existing key');
ok(!$o1->a_hash_exists('f'), "check exists() doesn't autovivify");
$o1->a_hash_delete(qw/c g/);
is_deeply({ $o1->a_hash }, { a => 23, b => 2 }, 'list context, new object');
$o1->a_hash({ a => 1, d => 5 });
is_deeply(
    { $o1->a_hash },
    { a => 1, b => 2, d => 5 },
    'append/overwrite using a hash ref'
);
is_deeply($o1->a_hash('d'), 5, 'return single value');
is_deeply([ $o1->a_hash([qw/d b/]) ], [ 5, 2 ], 'return hash slice');
is($o1->a_hash_count, 3, 'count hash keys');
$o1->a_hash_clear;
is_deeply([ $o1->keys_a_hash ], [], 'clear');
is($o1->a_hash_count, 0, 'count returns 0 after clear');
