use strict;
use warnings;

use Data::Dumper;
use Test::More;

use ArangoDB2;

my $res;

my $arango = ArangoDB2->new("http://localhost:8529", $ENV{ARANGO_USER}, $ENV{ARANGO_PASS});

my $dbname = "ngukvderybvfgjutecbxzsfhyujmnvgf";
my $database = $arango->database($dbname);
my $collection = $database->collection('foobar');
my $document = $collection->document();
my $query = $database->query();

# test required methods
my @methods = qw(
    batchSize
    count
    execute
    fullCount
    explain
    parse
    query
);

for my $method (@methods) {
    can_ok($query, $method);
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

# create collection
$res = $collection->create();
# create documents
$res = $document->create({test => "test"})
    for (1 .. 10);

$query->query('FOR f IN foobar RETURN f');
# explain
$res = $query->explain;
ok($res->{plan}, "explain");
# parse
$res = $query->parse;
ok($res->{collections}, "parse");
# execute
my $cursor = $query->batchSize(1)->execute;
ok(@{$cursor->data->{result}} == 1, "got cursor");

# delete
$res = $cursor->delete;
ok($res, "delete");
# delete
$res = $collection->delete();
# delete database
$res = $arango->database($dbname)->delete();

done_testing();
