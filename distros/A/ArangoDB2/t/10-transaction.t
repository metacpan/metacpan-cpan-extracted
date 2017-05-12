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
my $transaction = $database->transaction;

# test required methods
my @methods = qw(
    action
    collections
    execute
    lockTimeout
    params
    waitForSync
);

for my $method (@methods) {
    can_ok($transaction, $method);
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

# add some documents
$res = $collection->document->create({test => "test"})
    for (1 .. 10);

$res = $database->transaction->execute({
    action => q#function (){var db = require('internal').db; db.foobar.save({});  return db.foobar.count();}#,
    collections => {
        write => "foobar",
    },
});
is($res, 11, "transaction");

# delete
$res = $collection->delete();
# delete database
$res = $arango->database($dbname)->delete();

done_testing();
