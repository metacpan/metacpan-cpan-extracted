
use strict;
use warnings;

use Test::More tests => 34;

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
    skip($@, 34) if $@ && chomp $@;

    my ($tree, $childhash) = test_create_test_tree($dbh);

    my $node;
    my $siblings;
    my $sibling;

    $msg      = "get_siblings_to_the_right() returns no siblings for root node";
    $siblings = $tree->get_siblings_to_the_right();
    is(scalar(@$siblings), 0, $msg);

    $msg      = "get_siblings_to_the_left() returns no siblings for root node";
    $siblings = $tree->get_siblings_to_the_left();
    is(scalar(@$siblings), 0, $msg);

    #####

    $node = '1.1';

    $msg =
      "get_siblings_to_the_right() returns correct number of siblings for depth-1 node ($node)";
    $siblings = $childhash->{$node}->get_siblings_to_the_right();
    is(scalar(@$siblings), 2, $msg);

    $msg = "Object returned by get_siblings_to_the_right() ($node)";
    isa_ok($siblings->[0], 'DBIx::Tree::MaterializedPath::Node', $msg);
    isa_ok($siblings->[1], 'DBIx::Tree::MaterializedPath::Node', $msg);

    $msg =
      "get_siblings_to_the_right() returns expected siblings for depth-1 node ($node)";
    is($siblings->[0]->data->{name}, 'b', $msg);
    is($siblings->[1]->data->{name}, 'c', $msg);

    $msg =
      "get_siblings_to_the_left() returns correct number of siblings for depth-1 node ($node)";
    $siblings = $childhash->{$node}->get_siblings_to_the_left();
    is(scalar(@$siblings), 0, $msg);

    #####

    $node = '1.2';

    $msg =
      "get_siblings_to_the_right() returns correct number of siblings for depth-1 node ($node)";
    $siblings = $childhash->{$node}->get_siblings_to_the_right();
    is(scalar(@$siblings), 1, $msg);

    $msg =
      "get_siblings_to_the_right() returns expected siblings for depth-1 node ($node)";
    is($siblings->[0]->data->{name}, 'c', $msg);

    $msg =
      "get_siblings_to_the_left() returns correct number of siblings for depth-1 node ($node)";
    $siblings = $childhash->{$node}->get_siblings_to_the_left();
    is(scalar(@$siblings), 1, $msg);

    $msg =
      "get_siblings_to_the_left() returns expected siblings for depth-1 node ($node)";
    is($siblings->[0]->data->{name}, 'a', $msg);

    #####

    $node = '1.3';

    $msg =
      "get_siblings_to_the_right() returns correct number of siblings for depth-1 node ($node)";
    $siblings = $childhash->{$node}->get_siblings_to_the_right();
    is(scalar(@$siblings), 0, $msg);

    $msg =
      "get_siblings_to_the_left() returns correct number of siblings for depth-1 node ($node)";
    $siblings = $childhash->{$node}->get_siblings_to_the_left();
    is(scalar(@$siblings), 2, $msg);

    $msg = "Object returned by get_siblings_to_the_left() ($node)";
    isa_ok($siblings->[0], 'DBIx::Tree::MaterializedPath::Node', $msg);
    isa_ok($siblings->[1], 'DBIx::Tree::MaterializedPath::Node', $msg);

    $msg =
      "get_siblings_to_the_left() returns expected siblings for depth-1 node ($node)";
    is($siblings->[0]->data->{name}, 'a', $msg);
    is($siblings->[1]->data->{name}, 'b', $msg);

    #####

    $node = '1.3.1';
    $msg =
      "get_siblings_to_the_right() returns correct number of siblings for depth-2 node ($node)";
    $siblings = $childhash->{$node}->get_siblings_to_the_right();
    is(scalar(@$siblings), 1, $msg);

    $msg =
      "get_siblings_to_the_right() returns expected siblings for depth-2 node ($node)";
    is($siblings->[0]->data->{name}, 'e', $msg);

    $node = '1.3.2';
    $msg =
      "get_siblings_to_the_right() returns correct number of siblings for depth-2 node ($node)";
    $siblings = $childhash->{$node}->get_siblings_to_the_right();
    is(scalar(@$siblings), 0, $msg);

    $node = '1.3.1';
    $msg =
      "get_siblings_to_the_right() returns correct siblings using cached query ($node)";
    $siblings = $childhash->{$node}->get_siblings_to_the_right();
    is(scalar(@$siblings),           1,   $msg);
    is($siblings->[0]->data->{name}, 'e', $msg);

    $node = '1.3.1.1';
    $msg =
      "get_siblings_to_the_right() returns correct number of siblings for leaf node ($node)";
    $siblings = $childhash->{$node}->get_siblings_to_the_right();
    is(scalar(@$siblings), 0, $msg);

    $node = '1.1';
    $msg =
      "get_siblings_to_the_right() returns no data yet using delay_load ($node)";
    $siblings =
      $childhash->{$node}->get_siblings_to_the_right({delay_load => 1});
    ok(!exists $siblings->[0]->{_data}, $msg);
    ok(!exists $siblings->[1]->{_data}, $msg);

    $msg = "data now loaded using delay_load ($node)";
    is($siblings->[0]->data->{name}, 'b', $msg);
    is($siblings->[1]->data->{name}, 'c', $msg);

    $node = '1.3.1';
    $msg =
      "get_siblings_to_the_right() returns no data yet using delay_load ($node)";
    $siblings =
      $childhash->{$node}->get_siblings_to_the_right({delay_load => 1});
    ok(!exists $siblings->[0]->{_data}, $msg);

    $msg = "data now loaded using delay_load ($node)";
    is($siblings->[0]->data->{name}, 'e', $msg);

    $node = '1.3';
    $msg =
      "get_siblings_to_the_left() returns no data yet using delay_load ($node)";
    $siblings =
      $childhash->{$node}->get_siblings_to_the_left({delay_load => 1});
    ok(!exists $siblings->[0]->{_data}, $msg);
    ok(!exists $siblings->[1]->{_data}, $msg);

    $msg = "data now loaded using delay_load ($node)";
    is($siblings->[0]->data->{name}, 'a', $msg);
    is($siblings->[1]->data->{name}, 'b', $msg);
}

