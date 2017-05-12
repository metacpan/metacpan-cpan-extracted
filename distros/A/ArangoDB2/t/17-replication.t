use strict;
use warnings;

use Data::Dumper;
use Test::More;

use ArangoDB2;

my $res;

my $arango = ArangoDB2->new("http://localhost:8529", $ENV{ARANGO_USER}, $ENV{ARANGO_PASS});

my $dbname = "ngukvderybvfgjutecbxzsfhyujmnvgf";
my $database = $arango->database($dbname);
my $replication = $database->replication;

# test required methods
my @api_methods = qw(
    applierConfig
    applierStart
    applierState
    applierStop
    clusterInventory
    dump
    inventory
    loggerFollow
    loggerState
    serverId
    sync
);

my @methods = qw(
    chunkSize
    collection
    from
    includeSystem
    ticks
    to
);

for my $method (@methods, @api_methods) {
    can_ok($replication, $method);
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

ok($replication->inventory, "inventory");
ok($replication->serverId, "serverId");

# need cluster set up to test these
# ok($replication->clusterInventory, "clusterInventory");
# ok($replication->dump, "dump");
# ok($replication->sync, "sync");

ok($replication->loggerFollow, "loggerFollow");
ok($replication->loggerState, "loggerState");

ok($replication->applierConfig, "applierConfig");
ok($replication->applierState, "applierState");

# need cluster set up to test these
# ok($replication->applierStart, "applierStart");
# ok($replication->applierStop, "applierStop");

# delete database
$database->delete;

done_testing();
