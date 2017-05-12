use strict;
use warnings;

use Data::Dumper;
use Test::More;

use ArangoDB2;

my $res;

my $arango = ArangoDB2->new("http://localhost:8529", $ENV{ARANGO_USER}, $ENV{ARANGO_PASS});
my $endpoint = $arango->endpoint;

# test required methods
my @api_methods = qw(
    create
    delete
    list
);

my @methods = qw(
    name
    databases
);

for my $method (@methods, @api_methods) {
    can_ok($endpoint, $method);
}

# skip tests against the actual ArangoDB server unless
# LIVE_TEST env param is set
if (!$ENV{LIVE_TEST}) {
    diag("Skipping live API tests - set LIVE_TEST=1 to enable");
    done_testing();
    exit;
}

# create database
$arango->database("foo")->create;

# create endpoint
$res = $endpoint->name("tcp://localhost:8530")->create({
    databases => ["foo"],
});
ok($res, "create endpoint");

# get list
$res = $endpoint->list;
ok($res, "list");
my($end) = grep {$_->{endpoint} eq "tcp://localhost:8530"} @$res;
ok($end, "endpoint exists" );
is_deeply($end->{databases}, ['foo'], "endpoint: databases");

# delete endpoint
$res = $endpoint->delete;
ok($res, "endpoint delete");

# get list
$res = $endpoint->list;
($end) = grep {$_->{endpoint} eq "tcp://localhost:8530"} @$res;
ok(!$end, "endpoint does not exist" );

# delete database
$arango->database("foo")->delete;

done_testing();
