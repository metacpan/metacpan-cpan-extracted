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
my $vertex = $vertexCollection->vertex;

# test required methods
my @methods = qw(
    create
    delete
    get
    keepNull
    new
    update
    replace
    waitForSync
);

for my $method (@methods) {
    can_ok($vertex, $method);
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
                "foo",
            ],
            to => [
                "bar",
            ],
        },
    ],
});

# create vertex
$vertex = $graph->vertexCollection('foo')->vertex->create({test => "test"});
ok($vertex, "create");
ok($vertex->name, "create: name");
ok($vertex->id, "create: id");
ok($vertex->rev, "create: rev");
ok($vertex->data, "create: data");
ok($graph->vertexCollection('foo')->vertices->{$vertex->name}, "create: vertex registered");

# get vertex
$vertex = $graph->vertexCollection('foo')->vertex->get({name => $vertex->name});
ok($vertex, "get");
ok($vertex->name, "get: name");
ok($vertex->id, "get: id");
ok($vertex->rev, "get: rev");
ok($vertex->data, "get: data");
ok($graph->vertexCollection('foo')->vertices->{$vertex->name}, "get: vertex registered");

# update
$vertex->update({hello => "world"});

# get vertex again
$vertex = $graph->vertexCollection('foo')->vertex->get({name => $vertex->name});
is($vertex->data->{hello}, "world", "data updateed");

# replace
$vertex->replace({another => "test"});

# get vertex again
$vertex = $graph->vertexCollection('foo')->vertex->get({name => $vertex->name});
is_deeply($vertex->data, {another => "test"}, "data replaced");

# delete vertex
$res = $vertex->delete;
ok($res, "delete");

# get vertex again
$vertex = $graph->vertexCollection('foo')->vertex->get({name => $vertex->name});
ok(!$vertex, "deleted");

# delete database
$database->delete;

done_testing();
