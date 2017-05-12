
use strict;
use warnings;

use Test::More tests => 5;

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
    skip($@, 5) if $@ && chomp $@;

    my ($tree, $childhash) = test_create_test_tree($dbh);

    my $children;
    my $child;
    my $parent;

    $msg = 'get_parent() returns undef for root';
    is($tree->get_parent(), undef, $msg);

    $children = $tree->get_children();
    $child    = $children->[2];
    $parent   = $child->get_parent();

    $msg = 'Object returned by get_parent() for depth-1 child';
    isa_ok($parent, 'DBIx::Tree::MaterializedPath::Node', $msg);

    $msg = 'get_parent() returns root for depth-1 child';
    is($parent->data->{name}, $tree->data->{name}, $msg);

    $children = $child->get_children();
    $child    = $children->[1];
    $parent   = $child->get_parent();

    $msg = 'Object returned by get_parent() for deeper child';
    isa_ok($parent, 'DBIx::Tree::MaterializedPath::Node', $msg);

    $msg = 'get_parent() returns correct node for deeper child';
    is($parent->data->{name}, 'c', $msg);
}

