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
my $edgeDefinition = $graph->edgeDefinition;

# test required methods
my @methods = qw(
    new
    create
    delete
    dropCollection
    from
    list
    replace
    to
);

for my $method (@methods) {
    can_ok($edgeDefinition, $method);
}

# skip tests against the actual ArangoDB server unless
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

# create edge collection
$edgeDefinition = $graph->edgeDefinition("moreEdges")->from(["foo"])->to(["bar"])->create;
ok($edgeDefinition, "edgeDefinition created");
ok($edgeDefinition->name, "name");
ok($edgeDefinition->from, "from");
ok($edgeDefinition->to, "to");

# list
my $list = $edgeDefinition->list;
ok($list, "list");
ok( grep(/moreEdges/, @$list), "edgeDefinition exists");

# replace
$res = $edgeDefinition->replace({
    from => ['hello'],
    to => ['world'],
});

# delete
$res = $edgeDefinition->delete;
ok($res, "delete");

# list
$list = $edgeDefinition->list;
ok( !grep(/moreEdges/, @$list), "edgeDefinition does not exist");

# delete database
$database->delete;

done_testing();
