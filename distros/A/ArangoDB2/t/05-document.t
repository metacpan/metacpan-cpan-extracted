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
my $document = $collection->document();
isa_ok($document, 'ArangoDB2::Document');

# test required methods
my @methods = qw(
    create
    createCollection
    data
    delete
    edges
    get
    head
    keepNull
    list
    new
    update
    policy
    replace
    rev
    type
    waitForSync
);

for my $method (@methods) {
    can_ok($document, $method);
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

# create document
$res = $document->create({test => "test"});
ok($res, "create: document created");
ok($document->name, "create: name set");
ok($document->rev, "create: rev set");
is_deeply($document->data, {test => "test"}, "create: local data set");
is($document, $collection->document($document->name), "create: document registered");

# get document
$document->get();
is_deeply($document->data, {test => "test"}, "get: local data set");
ok($document->rev, "get: rev set");

# delete document from register so we can get get it again
delete $collection->documents->{test};

# get document from name
$document = $collection->document($document->name);
is_deeply($document->data, {test => "test"}, "new(name): local data set");

# replace
$res = $document->replace({test2 => "test2"});
ok($res, "replace");
is_deeply($document->data, {test2 => "test2"}, "replace: local data set");

# update
$res = $document->update({test3 => "test3"});
is($document->data->{test2}, "test2", "update: local data set");
is($document->data->{test3}, "test3", "update: local data set");

# head
$res = $document->head();
is($res, 200, "head: document exists");

# list
$res = $collection->document->list();
ok($res->{documents}, "list");

# delete
$res = $document->delete();
is_deeply($document->data, {}, "delete: local data deleted");

# try getting again
$document = $collection->document($res->{_key});
ok(!$document->rev, "delete: document deleted");

# delete
$res = $collection->delete();
# delete database
$res = $arango->database($dbname)->delete();

done_testing();
