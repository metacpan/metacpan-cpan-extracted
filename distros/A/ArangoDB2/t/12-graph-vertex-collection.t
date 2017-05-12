use strict;
use warnings;

use Data::Dumper;
use Test::More;

use ArangoDB2;

my $res;

my $arango = ArangoDB2->new("http://localhost:8529", $ENV{ARANGO_USER}, $ENV{ARANGO_PASS});

my $dbname = "ngukvderybvfgjutecbxzsfhyujmnvgf";
my $database = $arango->database($dbname);
my $graph = $database->graph;
my $vertexCollection = $graph->vertexCollection;

# test required methods
my @methods = qw(
    new
    create
    delete
    dropCollection
    list
);

for my $method (@methods) {
    can_ok($vertexCollection, $method);
}

# skip tests against the actual ArangoDB2 server unless
# LIVE_TEST env param is set
if (!$ENV{LIVE_TEST}) {
    diag("Skipping live API tests - set LIVE_TEST=1 to enable");
    done_testing();
    exit;
}

# delete database
$database->delete;
# create database
$database->create({
    users => [
        {
            username => $ENV{ARANGO_USER},
            passwd => $ENV{ARANGO_PASS},
        },
    ],
});

# create a new graph
$graph = $database->graph("myGraph")->create({
    edgeDefinitions => [
        {
            collection => "edges",
            from => [
                "startVertices",
            ],
            to => [
                "endVertices",
            ],
        },
    ],
});

# create vertex collection
$vertexCollection = $graph->vertexCollection("moreVertices")->create;
ok($vertexCollection, "vertexCollection created");

# list vertex collections
my $list = $graph->vertexCollection->list;
ok($list, "list");
ok( (grep {$_ =~ "moreVertices"} @$list), "vertextCollection exists" );

# delete vertex collection
$vertexCollection->delete;
$list = $graph->vertexCollection->list;
ok( !(grep {$_ =~ "moreVertices"} @$list), "vertextCollection deleted" );

# delete graph
ok($graph->delete, "delete");

# delete database
$database->delete;

done_testing();
