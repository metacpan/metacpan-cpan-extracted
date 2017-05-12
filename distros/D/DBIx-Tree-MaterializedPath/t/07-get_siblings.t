
use strict;
use warnings;

use Test::More tests => 27;

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
    skip($@, 27) if $@ && chomp $@;

    my ($tree, $childhash) = test_create_test_tree($dbh);

    my $siblings;
    my $sibling;

    $msg = 'get_siblings() returns correct number of siblings for root node';
    $siblings = $tree->get_siblings();
    is(scalar(@$siblings), 1, $msg);

    $msg = 'get_siblings() returns correct node for root node';
    ok($tree->is_same_node_as($siblings->[0]), $msg);

    $msg = 'get_siblings() returns correct number of siblings for depth-1 node';
    $siblings = $childhash->{'1.2'}->get_siblings();
    is(scalar(@$siblings), 3, $msg);

    $msg = 'Object returned by get_siblings()';
    isa_ok($siblings->[0], 'DBIx::Tree::MaterializedPath::Node', $msg);
    isa_ok($siblings->[1], 'DBIx::Tree::MaterializedPath::Node', $msg);
    isa_ok($siblings->[2], 'DBIx::Tree::MaterializedPath::Node', $msg);

    $msg = 'get_siblings() returns expected siblings for depth-1 node';
    is($siblings->[0]->data->{name}, 'a', $msg);
    is($siblings->[1]->data->{name}, 'b', $msg);
    is($siblings->[2]->data->{name}, 'c', $msg);

    $msg = 'get_siblings() returns correct number of siblings for depth-2 node';
    $siblings = $childhash->{'1.3.1'}->get_siblings();
    is(scalar(@$siblings), 2, $msg);

    $msg = 'get_siblings() returns expected siblings for depth-2 node';
    is($siblings->[0]->data->{name}, 'd', $msg);
    is($siblings->[1]->data->{name}, 'e', $msg);

    $msg      = 'get_siblings() returns correct siblings using cached query';
    $siblings = $childhash->{'1.3.1'}->get_siblings();
    is(scalar(@$siblings),           2,   $msg);
    is($siblings->[0]->data->{name}, 'd', $msg);
    is($siblings->[1]->data->{name}, 'e', $msg);

    $msg = 'get_siblings() returns correct number of siblings for leaf node';
    $siblings = $childhash->{'1.3.1.1'}->get_siblings();
    is(scalar(@$siblings), 1, $msg);

    $msg = 'get_siblings() returns correct node for leaf node';
    is($siblings->[0]->data->{name}, 'f', $msg);

    $msg = 'get_siblings() returns no data yet using delay_load';
    $siblings = $childhash->{'1.1'}->get_siblings({delay_load => 1});
    ok(!exists $siblings->[0]->{_data}, $msg);
    ok(!exists $siblings->[1]->{_data}, $msg);
    ok(!exists $siblings->[2]->{_data}, $msg);

    $msg = 'data now loaded using delay_load';
    is($siblings->[0]->data->{name}, 'a', $msg);
    is($siblings->[1]->data->{name}, 'b', $msg);
    is($siblings->[2]->data->{name}, 'c', $msg);

    $msg = 'get_siblings() returns no data yet using delay_load';
    $siblings = $childhash->{'1.3.2'}->get_siblings({delay_load => 1});
    ok(!exists $siblings->[0]->{_data}, $msg);
    ok(!exists $siblings->[1]->{_data}, $msg);

    $msg = 'data now loaded using delay_load';
    is($siblings->[0]->data->{name}, 'd', $msg);
    is($siblings->[1]->data->{name}, 'e', $msg);
}

