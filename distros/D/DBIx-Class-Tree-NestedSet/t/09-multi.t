use strict;
use warnings;
use Test::More tests => 32;
use DBICx::TestDatabase;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/tlib";

BEGIN { use_ok('TestSchema') }

my $schema = DBICx::TestDatabase->new('TestSchema');
isa_ok($schema, 'DBIx::Class::Schema');

my $trees = $schema->resultset('MultiTree');
isa_ok($trees, 'DBIx::Class::ResultSet');

my $root = $trees->create({ content => 'foo' });
isa_ok($root, 'DBIx::Class::Row');

is($root->parent, undef, 'root has no parent');
is($root->root->id, $root->id, 'root field gets set automatically');
is($root->descendants->count, 0, 'no descendants, initially');
is($root->nodes->count, 1, 'nodes include self');

ok( $root->is_root,   'is_root()');
ok( $root->is_leaf,   'is_leaf()');
ok(!$root->is_branch, 'is_branch()');

my $child = $root->add_to_children({ content => 'bar' });
is($child->root->id, $root->id, 'root set for descendants');
is($child->ancestors->count, 1, 'child got one parent');
is($child->parent->id, $root->id, 'parent rel works');
is($root->descendants->count, 1, 'now one child');
is($root->nodes->count, 2, '... and two related nodes');

ok( $root->is_root,    'is_root()');
ok(!$root->is_leaf,    'is_leaf()');
ok( $root->is_branch,  'is_branch()');
ok(!$child->is_root,   'is_root()');
ok( $child->is_leaf,   'is_leaf()');
ok(!$child->is_branch, 'is_branch()');

my $child2 = $root->add_to_children({ content => 'kooh' });

my $subchild = $child->add_to_children({ content => 'moo' });
my $subchild2 = $child->add_to_children({ content => 'right' });
is($subchild->root->id, $root->id, 'root set for subchilds');
is($root->descendants->count, 4, 'root now four descendants');
is($root->nodes->count, 5, '... and five related nodes');
is($child->descendants->count, 2, 'subnode has two descendants');
is($child->nodes->count, 5, '... and five related nodes as well');
is($subchild->descendants->count, 0, 'subchild does not have descendants yet');
is($subchild->ancestors->count, 2, '... but two ancestors');
is($subchild->parent->id, $child->id, 'direct parent is correct');

is_deeply(
    [map { $_->id } $subchild->ancestors],
    [map { $_->id } $child, $root],
    'ancestors are ordered correctly',
);

is_deeply(
    [map { $_->id } $root->descendants],
    [map { $_->id } $child, $subchild, $subchild2, $child2],
    'roots descendants are ordered correctly',
);
