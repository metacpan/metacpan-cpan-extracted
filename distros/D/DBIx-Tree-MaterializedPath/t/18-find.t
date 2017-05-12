
use strict;
use warnings;

use Test::More tests => 29;

use DBIx::Tree::MaterializedPath;

BEGIN
{
    chdir 't' if -d 't';
    use File::Spec;
    my $testlib = File::Spec->catfile('testlib', 'testutils.pm');
    require $testlib;
}

my $msg;

SKIP:
{
    my $dbh;
    eval { $dbh = test_get_dbh() };
    skip($@, 29) if $@ && chomp $@;

    my ($tree, $childhash) = test_create_test_tree($dbh);

    my $nodes;
    my $node;

    $msg = 'find() should catch missing input';
    eval { $nodes = $tree->find(); };
    like($@, qr/\bmissing\b .* \bwhere\b/ix, $msg);

    $msg = 'find() should catch bad input';
    eval { $nodes = $tree->find({name => 'a'}); };
    like($@, qr/\bmissing\b .* \bwhere\b/ix, $msg);

    $msg = 'find() simple query (options list)';
    $nodes = $tree->find(where => {name => 'a'});
    is(scalar(@$nodes), 1, $msg . ' returns correct number of nodes');
    isa_ok($nodes->[0], 'DBIx::Tree::MaterializedPath::Node', 'Returned node');
    is($nodes->[0]->data->{name}, 'a', $msg . ' returns correct node');

    $msg = 'find() simple query (options hashref)';
    $nodes = $tree->find({where => {name => 'a'}});
    is(scalar(@$nodes), 1, $msg . ' returns correct number of nodes');
    is($nodes->[0]->data->{name}, 'a', $msg . ' returns correct node');

    $msg = 'find() LIKE query';
    $nodes = $tree->find(where => {name => {-like => 'e%'}});
    is(scalar(@$nodes), 1, $msg . ' returns correct number of nodes');
    is($nodes->[0]->data->{name}, 'e', $msg . ' returns correct node');

    $msg = 'find() OR query';
    $nodes = $tree->find(where => [{name => 'a'}, {name => 'f'}]);
    is(scalar(@$nodes), 2, $msg . ' returns correct number of nodes');
    is($nodes->[0]->data->{name}, 'a', $msg . ' returns correct node');
    is($nodes->[1]->data->{name}, 'f', $msg . ' returns correct node');

    $msg = 'find() AND query';
    $nodes =
      $tree->find(where => {name => [-and => {-like => 'b%'}, {'!=' => 'c'}]});
    is(scalar(@$nodes), 1, $msg . ' returns correct number of nodes');
    is($nodes->[0]->data->{name}, 'b', $msg . ' returns correct node');

    $msg = 'find() order by';
    $nodes = $tree->find(where    => [{name => 'a'}, {name => 'f'}],
                         order_by => ['name DESC']);
    is(scalar(@$nodes), 2, $msg . ' returns correct number of nodes');
    is($nodes->[0]->data->{name}, 'f', $msg . ' returns correct node');
    is($nodes->[1]->data->{name}, 'a', $msg . ' returns correct node');

    $msg = 'find() on non-existent descendant';
    $nodes = $tree->find(where => {name => 'non-existant'});
    is(scalar(@$nodes), 0, $msg . ' returns correct number of nodes');

    $msg = 'find() returns no data yet using delay_load';
    $nodes =
      $tree->find(where => [{name => 'a'}, {name => 'f'}], delay_load => 1);
    ok(!exists $nodes->[0]->{_data}, $msg);
    ok(!exists $nodes->[1]->{_data}, $msg);

    $msg = 'data now loaded using delay_load';
    is($nodes->[0]->data->{name}, 'a', $msg);
    is($nodes->[1]->data->{name}, 'f', $msg);

    $node = $childhash->{'1.3'};

    $msg = 'find() on child node';
    $nodes = $node->find(where => {name => ['a', 'd', 'e', 'f']});
    is(scalar(@$nodes), 3, $msg . ' returns correct number of nodes');
    is($nodes->[0]->data->{name}, 'd', $msg . ' returns correct node');
    is($nodes->[1]->data->{name}, 'f', $msg . ' returns correct node');
    is($nodes->[2]->data->{name}, 'e', $msg . ' returns correct node');

    $msg = 'find() on child node for non-existent descendant';
    $nodes = $node->find(where => {name => 'b'});
    is(scalar(@$nodes), 0, $msg . ' returns correct number of nodes');

    test_initialize_join_table($dbh, 'my_join_data');

    $msg = 'find() across tables';
    $nodes = $tree->find(
                         extra_tables => ['my_join_data'],
                         where        => {
                                   'my_join_data.data' => 'BBB',
                                   'my_join_data.name' => \'= my_tree.name'
                                  }
                        );
    is(scalar(@$nodes), 1, $msg . ' returns correct number of nodes');
    is($nodes->[0]->data->{name}, 'b', $msg . ' returns correct node');
}

