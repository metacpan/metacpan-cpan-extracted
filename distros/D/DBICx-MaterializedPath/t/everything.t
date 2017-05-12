use Test::More "no_plan";
use warnings;
use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestSchema;
use DBICx::TestDatabase;

my $NOW = \"datetime('now')"; # "

ok( my $schema = DBICx::TestDatabase->new("TestSchema"),
    'Instantiating DBICx::TestDatabase->new("TestSchema")'
    );

# id, parent, content, created
ok( my $node = $schema->resultset("TreeData")->create({ content => "OH HAI",
                                                        created => $NOW }),
    "Creating a record"
    );

is( $node->path, $node->id,
    "The path and the id are the same value for root nodes" );

my $last = $node;
my $subtests = 0;
for my $new ( 1 .. 3 )
{
    ok( my $kid = $schema->resultset("TreeData")->create({ content => "Kid #$new",
                                                           parent => $last,
                                                           created => $NOW }),
        "Creating a new record"
      );

    $kid->discard_changes; # Refresh from DB.

    is( $kid->node_depth, $new + 1,
        "Node depth " . ( $new + 1 ) . " is right" );

    ok( my @ancestors = $kid->ancestors,
        "Getting ancestors" );

    cmp_ok( scalar(@ancestors), "==", $new,
            sprintf("Ancestor count for record %s (path:%s) is sensible",
                    $kid->id, $kid->path )
          );

    my @sorted = sort { length($a->path) <=> length($b->path) } @ancestors;

    is_deeply( \@sorted, \@ancestors,
               "Ancestors are returned in appropriate order" );

    my @flat_ancestors = map { +{ $_->get_columns } } @ancestors;
    my @flat_computed = map { +{ $_->get_columns } } $kid->_compute_ancestors;
    is_deeply( \@flat_ancestors, \@flat_computed,
               "Ancestors == computed ancestors" );

    $last = $kid;
}

is( $last->root_node->id, $node->id,
    "Original node is the root of the last child" );

# Add three children to every record.
for my $rec ( $schema->resultset("TreeData")->search({},{order_by => "id"}) )
{
    next unless $rec->node_depth > 1; # Not the root.
    for my $new ( 1 .. 3 )
    {
        my $kid = $schema->resultset("TreeData")
            ->create({ content => "Kid #$new of #" . $rec->id,
                       parent => $rec,
                       created => $NOW });
        $last = $kid;
    }
}

is( $last->root_node->id, $node->id,
    "Original node is the root of most recent last child" );

ok( my @descendants = $node->grandchildren,
    "Getting grandchildren for original node" );

is( scalar( @descendants ), 12,
    "Correct number of granchildren found" );

ok( my $new_node = $schema->resultset("TreeData")
        ->create({ content => "A new root",
                   created => $NOW }),
    "Creating a new rootless node" );


isnt( $last->root_node->id, $new_node->id,
      "New node isn't the root of the last added child" );

$node->parent($new_node);
$node->update;

$last->discard_changes;

is( $last->root_node->id, $new_node->id,
    "New node is now the root of the last added child" );

__END__

Test removing the parent too?
