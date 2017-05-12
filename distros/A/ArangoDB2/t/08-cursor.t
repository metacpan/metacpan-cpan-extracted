use strict;
use warnings;

use Data::Dumper;
use Test::More;

use ArangoDB2;
use ArangoDB2::Cursor;

my $res;

my $arango = ArangoDB2->new("http://localhost:8529", $ENV{ARANGO_USER}, $ENV{ARANGO_PASS});

my $dbname = "ngukvderybvfgjutecbxzsfhyujmnvgf";
my $database = $arango->database($dbname);
my $collection = $database->collection('foobar');
my $document = $collection->document();
my $query = $database->query();

# we can't get a real cursor without doing a query
# so we will just create one to test the methods
my $cursor = ArangoDB2::Cursor->new($arango, $database, {});

# test required methods
my @methods = qw(
    all
    count
    delete
    each
    fullCount
    get
    next
);

for my $method (@methods) {
    can_ok($cursor, $method);
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
# execute
$cursor = $query->batchSize(1)->execute;
ok(@{$cursor->data->{result}} == 1, "got cursor");
my $data = $cursor->data->{result}->[0];
is($data, $cursor->next, "next");
# there should be nine more records
for my $i (1..9) {
    ok($cursor->next, "next: record");
}
# now there should be no more records
ok(!$cursor->next, "next: no more records");
# do query again
$cursor = $query->batchSize(1)->execute;
ok(@{$cursor->all} == 10, "all: count correct");
# do query again
$cursor = $query->batchSize(1)->execute;
my $i = 0;
$cursor->each(sub { $i++ });
ok($i == 10, "each: count correct");
# get count
$cursor = $query->count(1)->execute;
ok($cursor->count == 10, "count");
# redo query with limit
$query = $database->query('FOR f IN foobar LIMIT 5 RETURN f');
$cursor = $query->count(1)->execute;
ok($cursor->count == 5, "count with LIMIT");
# redo query with fullCount
$cursor = $query->fullCount(1)->batchSize(1)->execute;
ok($cursor->fullCount == 10, "fullCount with LIMIT");

# delete
$res = $cursor->delete;
ok($res, "delete");
# delete
$res = $collection->delete();
# delete database
$res = $arango->database($dbname)->delete();

done_testing();
