use strict;
use warnings;

use Data::Dumper;
use Test::More;

use ArangoDB2;

my $res;

my $arango = ArangoDB2->new("http://localhost:8529", $ENV{ARANGO_USER}, $ENV{ARANGO_PASS});

my $dbname = "ngukvderybvfgjutecbxzsfhyujmnvgf";
my $database = $arango->database($dbname);
my $collection = $database->collection('test');
isa_ok($collection, 'ArangoDB2::Collection');

# test required methods
my @methods = qw(
    checksum
    count
    create
    delete
    document
    documents
    documentCount
    doCompact
    edge
    edges
    excludeSystem
    figures
    index
    indexes
    info
    isSystem
    isVolatile
    journalSize
    keyOptions
    list
    load
    numberOfShards
    properties
    rename
    revision
    rotate
    shardKeys
    truncate
    type
    unload
    waitForSync
    withData
    withRevisions
);

for my $method (@methods) {
    can_ok($collection, $method);
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
ok($res, "create collection");

# list
$res = $collection->list({excludeSystem => 1});
ok($res->{names}->{test}, "collection exists");
# properties
$res = $collection->properties();
ok($res->{name}, "properties");
# info
$res = $collection->info();
ok($res->{name}, "info");
# count
$res = $collection->documentCount();
ok(defined $res->{count}, "documentCount");
# figures
$res = $collection->figures();
ok(defined $res->{figures}, "figures");
# revision
$res = $collection->revision();
ok(defined $res->{revision}, "revision");
# checksum
$res = $collection->checksum();
ok(defined $res->{checksum}, "checksum");

# set properties
$res = $collection->properties({
    waitForSync => "true",
    journalSize => 1048576,
});
ok($res->{waitForSync}, "properties: waitForSync");
ok($res->{journalSize} == 1048576, "properties: journalSize");

# rotate
$res = $collection->rotate();
ok(!$res, "rotate failed with no writes");

# rename
$res = $collection->rename({name => "test2"});
is($collection->name, "test2", "name changed");
is($collection, $database->collection("test2"), "register changed");

# load
$res = $collection->load();
ok(defined $res->{count}, "load");
# unload
$res = $collection->unload();
ok(defined $res->{name}, "unload");

# truncate
$res = $collection->truncate();
ok(defined $res->{name}, "truncate");

# delete
$res = $collection->delete();
# list collections
$res = $collection->list({excludeSystem => 1});
ok(!$res->{names}->{test}, "collection deleted");

# delete database
$res = $arango->database($dbname)->delete();

done_testing();
