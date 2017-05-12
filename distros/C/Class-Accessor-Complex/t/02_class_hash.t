#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 15;

package Foo;
use parent 'Class::Accessor::Complex';
__PACKAGE__->mk_new->mk_class_hash_accessors(qw(a_hash));

package main;
can_ok(
    'Foo', qw(
      a_hash a_hash_clear a_hash_keys a_hash_values a_hash_exists a_hash_delete
      )
);
is_deeply([ Foo->new->a_hash_keys ], [], 'empty to begin with');
my $o1 = Foo->new;
$o1->a_hash(a => 1, b => 2);
my %o1 = $o1->a_hash;
is_deeply(\%o1, { a => 1, b => 2 }, 'return hash in list context');
is_deeply(
    { Foo->new->a_hash },
    { a => 1, b => 2 },
    'return hash in list context, new object'
);
Foo->new->a_hash(a => 23, c => 4);
is_deeply({ Foo->new->a_hash }, { a => 23, b => 2, c => 4 },
    'append/overwrite');
is_deeply([ sort Foo->new->a_hash_keys ], [qw/a b c/], 'keys');
is_deeply([ sort { $a <=> $b } Foo->new->a_hash_values ], [qw/2 4 23/],
    'value');
ok(Foo->new->a_hash_exists('b'),  'exists() with an existing key');
ok(!Foo->new->exists_a_hash('f'), 'exists() with a non-existing key');
ok(!Foo->new->a_hash_exists('f'), "check exists() doesn't autovivify");
Foo->new->a_hash_delete(qw/c g/);
is_deeply({ Foo->new->a_hash }, { a => 23, b => 2 },
    'list context, new object');
Foo->new->a_hash({ a => 1, d => 5 });
is_deeply(
    { Foo->new->a_hash },
    { a => 1, b => 2, d => 5 },
    'append/overwrite using a hash ref'
);
is_deeply(Foo->new->a_hash('d'), 5, 'return single value');
is_deeply([ Foo->new->a_hash([qw/d b/]) ], [ 5, 2 ], 'return hash slice');
Foo->new->a_hash_clear;
is_deeply([ Foo->new->keys_a_hash ], [], 'clear');
