
use strict;
use warnings;

use Test::More tests => 14;

use DBIx::Tree::MaterializedPath;

BEGIN
{
    chdir 't' if -d 't';
    use File::Spec;
    my $testlib = File::Spec->catfile('testlib', 'testutils.pm');
    require $testlib;
}

my $tree;
my $msg;

SKIP:
{
    my $dbh;
    eval { $dbh = test_get_dbh() };
    skip($@, 14) if $@ && chomp $@;

    my ($tree, $childhash) = test_create_test_tree($dbh);

    my $children = $tree->get_children();

    my $foo = bless {}, 'Foo';

    $msg = 'is_root() for root node';
    ok($tree->is_root, $msg);

    $msg = 'is_root() for child';
    ok(!$children->[0]->is_root, $msg);
    ok(!$children->[1]->is_root, $msg);
    ok(!$children->[2]->is_root, $msg);

    $msg = '_map_path/_unmap_path are consistent';
    is($tree->_unmap_path($tree->_map_path('1.2.3.4.5')), '1.2.3.4.5', $msg);

    $msg = 'is_same_node_as() should catch missing node';
    eval { $tree->is_same_node_as(); };
    like($@, qr/\bmissing\b .* \bnode\b/ix, $msg);

    $msg = 'is_same_node_as() should catch invalid node';
    eval { $tree->is_same_node_as('I am not a node'); };
    like($@, qr/\binvalid\b .* \bnode\b/ix, $msg);

    $msg = 'is_same_node_as() should catch invalid node';
    eval { $tree->is_same_node_as($foo); };
    like($@, qr/\binvalid\b .* \bnode\b/ix, $msg);

    $msg = 'is_same_node_as() for root node';
    ok($tree->is_same_node_as($tree), $msg);

    $msg = 'is_same_node_as() for child';
    ok($children->[0]->is_same_node_as($children->[0]),  $msg);
    ok(!$children->[1]->is_same_node_as($children->[0]), $msg);
    ok(!$children->[2]->is_same_node_as($children->[0]), $msg);

    $msg = 'get_root() for root node';
    ok($tree->is_same_node_as($tree->get_root), $msg);

    $msg = 'get_root() for child';
    ok($tree->is_same_node_as($children->[0]->get_root), $msg);
}

