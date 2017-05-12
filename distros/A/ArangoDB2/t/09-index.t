use strict;
use warnings;

use Data::Dumper;
use Test::More;

use ArangoDB2;

my $res;

my $arango = ArangoDB2->new("http://localhost:8529", $ENV{ARANGO_USER}, $ENV{ARANGO_PASS});

my $dbname = "ngukvderybvfgjutecbxzsfhyujmnvgf";
my $database = $arango->database($dbname);
my $collection = $database->collection('places');
my $index = $collection->index();

isa_ok($index, 'ArangoDB2::Index');

# test required methods
my @methods = qw(
    new
    byteSize
    constraint
    create
    delete
    fields
    geoJson
    get
    id
    ignoreNull
    isNewlyCreated
    list
    minLength
    size
    type
    unique
);

for my $method (@methods) {
    can_ok($index, $method);
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

#create collection
$res = $collection->create();

# create some data
$collection->document->create({
    city => "Portland",
    state => "Oregon",
    latitude => 45.527,
    longitude => -122.683,
});
$collection->document->create({
    city => "Vancouver",
    state => "Washington",
    latitude => 45.637,
    longitude => -122.670,
});
$collection->document->create({
    city => "Beaverton",
    state => "Oregon",
    latitude => 45.488,
    longitude => -122.813,
});

# create hash index
$res = $index->create({
    type => "hash",
    fields => ["city", "state"],
});
ok($res, "create hash index");
ok($index->name, "create: name");

# check list
$res = $index->list;
ok($res->{indexes}, "list");
ok( ( grep { $_->{id} eq $index->id } @{$res->{indexes}} ), "index created" );

# get index
$index = $collection->index->get({name => $index->name});
ok($index, "get index");
ok($index->name, "index: name");
ok($index->id, "index: id");

# delete index
$index->delete;

# check list
$res = $index->list;
ok( !( grep { $_->{id} eq $index->id } @{$res->{indexes}} ), "index deleted" );


# delete
$res = $collection->delete();
# delete database
$res = $arango->database($dbname)->delete();

done_testing();
