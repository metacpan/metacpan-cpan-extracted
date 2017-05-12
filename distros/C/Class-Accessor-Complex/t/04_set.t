#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 15;

package Foo;
use parent 'Class::Accessor::Complex';
__PACKAGE__->mk_new->mk_set_accessors(qw(testset));

package main;
can_ok(
    'Foo', qw(
      testset testset_insert testset_elements testset_delete testset_clear
      testset_contains testset_is_empty testset_size
      )
);
my $x = Foo->new;
$x->testset;    # provoke autovivification
isa_ok($x->{testset}, 'HASH');
ok($x->testset_is_empty, 'empty set');
is($x->testset_size, 0, '0 elements in empty set');
$x->testset_insert(qw/merkur venus erde/);
is($x->size_testset, 3, '3 elements after first insert');
is_deeply([ sort $x->testset_elements ],
    [qw/erde merkur venus/], 'elements returned');
$x->testset(qw/venus erde mars/);
is($x->testset_size, 4, '4 elements after second insert via direct method');
is_deeply(
    [ sort $x->testset_elements ],
    [qw/erde mars merkur venus/],
    'elements returned'
);
$x->testset_delete('venus');
is($x->testset_size, 3, '3 elements after delete');
is_deeply([ sort $x->testset_elements ],
    [qw/erde mars merkur/], 'elements returned');
ok($x->testset_contains('merkur'), 'contains merkur');
ok(!$x->contains_testset('venus'), 'does not contain venus');
ok($x->contains_testset('erde'),   'contains erde');
ok($x->testset_contains('mars'),   'contains mars');
$x->testset_clear;
ok($x->is_empty_testset, 'empty set after clear');
