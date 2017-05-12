use strict;
use warnings;

use Data::Dumper;
use Test::More;

use ArangoDB2;

my $res;

my $arango = ArangoDB2->new("http://localhost:8529", $ENV{ARANGO_USER}, $ENV{ARANGO_PASS});
my $admin = $arango->admin;

# test required methods
my @api_methods = qw(
    echo
    execute
    log
    returnAsJSON
    routingReload
    serverRole
    shutdown
    statistics
    statisticsDescription
    test
    time
    walFlush
    walProperties
);

my @methods = qw(
    allowOversizeEntries
    level
    logfileSize
    historicLogfiles
    offset
    program
    reserveLogfiles
    search
    size
    sort
    start
    tests
    throttleWait
    throttleWhenPending
    upto
    waitForCollector
    waitForSync
);

for my $method (@methods, @api_methods) {
    can_ok($admin, $method);
}

# skip tests against the actual ArangoDB server unless
# LIVE_TEST env param is set
if (!$ENV{LIVE_TEST}) {
    diag("Skipping live API tests - set LIVE_TEST=1 to enable");
    done_testing();
    exit;
}

# echo
$res = $admin->echo;
ok($res, "echo");

# execute
$res = $admin->execute({
     program => q{ return 5; },
});
is($res, '"5"', "execute");

# log
$res = $admin->log;
ok($res, "log");

# routingReload
$res = $admin->routingReload;
ok($res, "routingReload");

# serverRole
$res = $admin->serverRole;
ok($res, "serverRole");

# shutdown
# $res = $admin->shutdown;
# ok($res, "shutdown");

# statistics
$res = $admin->statistics;
ok($res, "statistics");

# statisticsDescription
$res = $admin->statisticsDescription;
ok($res, "statisticsDescription");

# time
$res = $admin->time;
ok($res, "time");

# walFlush
$res = $admin->walFlush;
ok($res, "walFlush");

# walProperties
$res = $admin->walProperties;
ok($res, "walProperties");

# set walProperties
$res = $admin->walProperties({
    historicLogfiles => 5,
});
ok($res, "walProperties set");
is($res->{historicLogfiles}, 5, "historicLogfiles changed");

# set back
$res = $admin->walProperties({
    historicLogfiles => 10,
});
ok($res, "walProperties set");
is($res->{historicLogfiles}, 10, "historicLogfiles changed");

done_testing();
