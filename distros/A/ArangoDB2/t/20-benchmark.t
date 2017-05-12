#!/usr/bin/perl

use strict;
use warnings;

use ArangoDB2;
use Data::Dumper;
use Test::More;
use Time::HiRes qw(time);



ok(1, "dummy test");

# skip tests against the actual ArangoDB2 server unless
# LIVE_TEST env param is set
if (!$ENV{BENCHMARK}) {
    diag("Skipping benchmarks - set BENCHMARK=1 to enable");
    done_testing();
    exit;
}

my $NUM_REQUESTS = 10000;

my $arango = ArangoDB2->new("http://localhost:8529", $ENV{ARANGO_USER}, $ENV{ARANGO_PASS});

my $database = $arango->database("kisdmksadf");
$database->create({
    users => [
        {
            username => $ENV{ARANGO_USER},
            passwd   => $ENV{ARANGO_PASS},
        },
    ],
});

my $collection = $database->collection('test');
$collection->create;

my $document = $collection->document;
$document->create({foo => "bar"});

for my $client (qw(curl lwp)) {

    $arango->http_client($client);

    my $start = time;

    for (my $i=0; $i < $NUM_REQUESTS; $i++) {
        my $doc = $collection->document->name($document->name)->get;
        die "Request Failed"
            unless $doc;
    }

    my $run = time - $start;

    printf(
        "$client: %d GETS in %.2f secs, %.2f reqs/sec\n",
        $NUM_REQUESTS,
        $run,
        $NUM_REQUESTS / $run,
    );

}

$database->delete;

done_testing();
