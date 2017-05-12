
use strict;
use warnings;

use Test::More tests => 24;

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
    skip($@, 24) if $@ && chomp $@;

    my ($tree, $childhash) = test_create_test_tree($dbh);

    my $children;
    my $child;

    $msg = 'get_children() returns correct number of children for root node';
    $children = $tree->get_children();
    is(scalar(@$children), 3, $msg);

    $msg = 'Object returned by get_children()';
    isa_ok($children->[0], 'DBIx::Tree::MaterializedPath::Node', $msg);
    isa_ok($children->[1], 'DBIx::Tree::MaterializedPath::Node', $msg);
    isa_ok($children->[2], 'DBIx::Tree::MaterializedPath::Node', $msg);

    $msg = 'get_children() returns expected children for root node';
    is($children->[0]->data->{name}, 'a', $msg);
    is($children->[1]->data->{name}, 'b', $msg);
    is($children->[2]->data->{name}, 'c', $msg);

    $msg   = 'get_children() returns correct number of children for child node';
    $child = $children->[2];
    $children = $child->get_children();
    is(scalar(@$children), 2, $msg);

    $msg = 'get_children() returns expected children for child node';
    is($children->[0]->data->{name}, 'd', $msg);
    is($children->[1]->data->{name}, 'e', $msg);

    $msg      = 'get_children() returns correct children using cached query';
    $children = $child->get_children();
    is(scalar(@$children),           2,   $msg);
    is($children->[0]->data->{name}, 'd', $msg);
    is($children->[1]->data->{name}, 'e', $msg);

    $msg      = 'get_children() returns no children for leaf node';
    $child    = $children->[1];
    $children = $child->get_children();
    is(scalar(@$children), 0, $msg);

    $msg = 'get_children() returns no data yet using delay_load';
    $children = $tree->get_children({delay_load => 1});
    ok(!exists $children->[0]->{_data}, $msg);
    ok(!exists $children->[1]->{_data}, $msg);
    ok(!exists $children->[2]->{_data}, $msg);

    $msg = 'data now loaded using delay_load';
    is($children->[0]->data->{name}, 'a', $msg);
    is($children->[1]->data->{name}, 'b', $msg);
    is($children->[2]->data->{name}, 'c', $msg);

    $msg = 'get_children() returns no data yet using delay_load';
    $children = $children->[2]->get_children({delay_load => 1});
    ok(!exists $children->[0]->{_data}, $msg);
    ok(!exists $children->[1]->{_data}, $msg);

    $msg = 'data now loaded using delay_load';
    is($children->[0]->data->{name}, 'd', $msg);
    is($children->[1]->data->{name}, 'e', $msg);
}

