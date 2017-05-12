#!/usr/bin/perl
use Test::More tests => 63;
use strict;
use warnings;
BEGIN {
use_ok 'Data::Hierarchy';
}

# my belief:
# store (non-fast) recurses on entries that are actually changing the value
# store_fast never recurses
# store_recursively always does
#
# note that a store_recursively of a sticky property DELETES it from
# nodes underneath (whether or not your are changing it, etc)

my $TREE;

sub reset_tree {
    $TREE = Data::Hierarchy->new;

    $TREE->store('/foo', {a => 1, '.k' => 10});
    $TREE->store('/foo/bar', {a => 2, '.k' => 20});
}

sub test_foo_and_bar {
    my($foo, $foo_bar) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1; # report failures at call site
    is_deeply [$TREE->get('/foo')], $foo;
    is_deeply [$TREE->get('/foo/bar')], $foo_bar;
}

reset_tree();
test_foo_and_bar
  [{a => 1, '.k' => 10}, '/foo'],
  [{a => 2, '.k' => 20}, '/foo', '/foo/bar'];

reset_tree();
$TREE->store('/foo', {a => 3});
test_foo_and_bar
  [{a => 3, '.k' => 10}, '/foo'],
  [{a => 3, '.k' => 20}, '/foo'];

reset_tree();
$TREE->store('/foo', {a => 1});
test_foo_and_bar
  [{a => 1, '.k' => 10}, '/foo'],
  [{a => 1, '.k' => 20}, '/foo'];

reset_tree();
$TREE->store_recursively('/foo', {a => 1});
test_foo_and_bar
  [{a => 1, '.k' => 10}, '/foo'],
  [{a => 1, '.k' => 20}, '/foo'];

reset_tree();
$TREE->store_recursively('/foo', {a => 3});
test_foo_and_bar
  [{a => 3, '.k' => 10}, '/foo'],
  [{a => 3, '.k' => 20}, '/foo'];

reset_tree();
$TREE->store_fast('/foo', {a => 1});
test_foo_and_bar
  [{a => 1, '.k' => 10}, '/foo'],
  [{a => 2, '.k' => 20}, '/foo', '/foo/bar'];

reset_tree();
$TREE->store_fast('/foo', {a => 3});
test_foo_and_bar
  [{a => 3, '.k' => 10}, '/foo'],
  [{a => 2, '.k' => 20}, '/foo', '/foo/bar'];

reset_tree();
$TREE->store('/foo', {a => undef});
test_foo_and_bar
  [{'.k' => 10}],
  [{'.k' => 20}];

reset_tree();
$TREE->store_fast('/foo', {a => undef});
test_foo_and_bar
  [{'.k' => 10}],
  [{a => 2, '.k' => 20}, '/foo/bar'];

reset_tree();
$TREE->store_recursively('/foo', {a => undef});
test_foo_and_bar
  [{'.k' => 10}],
  [{'.k' => 20}];

# now start testing sticky

reset_tree();
$TREE->store('/foo', {'.k' => 30});
test_foo_and_bar
  [{a => 1, '.k' => 30}, '/foo'],
  [{a => 2, '.k' => 20}, '/foo', '/foo/bar'];

reset_tree();
$TREE->store('/foo', {'.k' => 10});
test_foo_and_bar
  [{a => 1, '.k' => 10}, '/foo'],
  [{a => 2, '.k' => 20}, '/foo', '/foo/bar'];

reset_tree();
$TREE->store_recursively('/foo', {'.k' => 10});
test_foo_and_bar
  [{a => 1, '.k' => 10}, '/foo'],
  [{a => 2}, '/foo', '/foo/bar'];

reset_tree();
$TREE->store_recursively('/foo', {'.k' => 30});
test_foo_and_bar
  [{a => 1, '.k' => 30}, '/foo'],
  [{a => 2}, '/foo', '/foo/bar'];

reset_tree();
$TREE->store_fast('/foo', {'.k' => 10});
test_foo_and_bar
  [{a => 1, '.k' => 10}, '/foo'],
  [{a => 2, '.k' => 20}, '/foo', '/foo/bar'];

reset_tree();
$TREE->store_fast('/foo', {'.k' => 30});
test_foo_and_bar
  [{a => 1, '.k' => 30}, '/foo'],
  [{a => 2, '.k' => 20}, '/foo', '/foo/bar'];


reset_tree();
$TREE->store('/foo', {'.k' => undef});
test_foo_and_bar
  [{a => 1}, '/foo'],
  [{a => 2, '.k' => 20}, '/foo', '/foo/bar'];

reset_tree();
$TREE->store_recursively('/foo', {'.k' => undef});
test_foo_and_bar
  [{a => 1}, '/foo'],
  [{a => 2}, '/foo', '/foo/bar'];

reset_tree();
$TREE->store_fast('/foo', {'.k' => undef});
test_foo_and_bar
  [{a => 1}, '/foo'],
  [{a => 2, '.k' => 20}, '/foo', '/foo/bar'];



# now testing assigns to /foo/bar (with store_override too)

reset_tree();
$TREE->store('/foo/bar', {a => 2});
test_foo_and_bar
  [{a => 1, '.k' => 10}, '/foo'],
  [{a => 2, '.k' => 20}, '/foo', '/foo/bar'];

reset_tree();
$TREE->store('/foo/bar', {a => 1});
test_foo_and_bar
  [{a => 1, '.k' => 10}, '/foo'],
  [{a => 1, '.k' => 20}, '/foo'];

reset_tree();
$TREE->store('/foo/bar', {a => 3});
test_foo_and_bar
  [{a => 1, '.k' => 10}, '/foo'],
  [{a => 3, '.k' => 20}, '/foo', '/foo/bar'];

reset_tree();
$TREE->store_fast('/foo/bar', {a => 2});
test_foo_and_bar
  [{a => 1, '.k' => 10}, '/foo'],
  [{a => 2, '.k' => 20}, '/foo', '/foo/bar'];

reset_tree();
$TREE->store_fast('/foo/bar', {a => 1});
test_foo_and_bar
  [{a => 1, '.k' => 10}, '/foo'],
  [{a => 1, '.k' => 20}, '/foo'];

reset_tree();
$TREE->store_fast('/foo/bar', {a => 3});
test_foo_and_bar
  [{a => 1, '.k' => 10}, '/foo'],
  [{a => 3, '.k' => 20}, '/foo', '/foo/bar'];

reset_tree();
$TREE->store_recursively('/foo/bar', {a => 2});
test_foo_and_bar
  [{a => 1, '.k' => 10}, '/foo'],
  [{a => 2, '.k' => 20}, '/foo', '/foo/bar'];

reset_tree();
$TREE->store_recursively('/foo/bar', {a => 1});
test_foo_and_bar
  [{a => 1, '.k' => 10}, '/foo'],
  [{a => 1, '.k' => 20}, '/foo'];

reset_tree();
$TREE->store_recursively('/foo/bar', {a => 3});
test_foo_and_bar
  [{a => 1, '.k' => 10}, '/foo'],
  [{a => 3, '.k' => 20}, '/foo', '/foo/bar'];

reset_tree();
$TREE->store_override('/foo/bar', {a => 2});
test_foo_and_bar
  [{a => 1, '.k' => 10}, '/foo'],
  [{a => 2, '.k' => 20}, '/foo', '/foo/bar'];

reset_tree();
$TREE->store_override('/foo/bar', {a => 1});
test_foo_and_bar
  [{a => 1, '.k' => 10}, '/foo'],
  [{a => 1, '.k' => 20}, '/foo'];

reset_tree();
$TREE->store_override('/foo/bar', {a => 3});
test_foo_and_bar
  [{a => 1, '.k' => 10}, '/foo'],
  [{a => 3, '.k' => 20}, '/foo', '/foo/bar'];

