use strict;
use warnings;

use Data::Dumper;
use Test::More;

use ArangoDB2;

my $res;

my $arango = ArangoDB2->new("http://localhost:8529", $ENV{ARANGO_USER}, $ENV{ARANGO_PASS});

# test required methods
my @methods = qw(
    collection
    collections
    create
    current
    delete
    list
    user
    userDatabases
);

for my $method (@methods) {
    can_ok($arango->database, $method);
}

# test for sub objects accessors
isa_ok($arango->database->collection('test'), 'ArangoDB2::Collection');

# skip tests against the actual ArangoDB2 server unless
# LIVE_TEST env param is set
if (!$ENV{LIVE_TEST}) {
    diag("Skipping live API tests - set LIVE_TEST=1 to enable");
    done_testing();
    exit;
}

$res = $arango->database->current;
ok(defined $res->{name}, 'current: name');
ok(defined $res->{id}, 'current: id');
ok(defined $res->{path}, 'current: path');
ok(defined $res->{isSystem}, 'current: isSystem');

$res = $arango->database->userDatabases;
ok(@$res, "user: database list");

$res = $arango->database->list;
ok(@$res, "list: database list");

my $dbname = "ngukvderybvfgjutecbxzsfhyujmnvge";

$res = $arango->database($dbname)->create();
ok($res, "create database");

$res = $arango->database->list;
ok(grep(/$dbname/, @$res), "database exists");

$res = $arango->database($dbname)->delete();
ok($res, "delete database");

$res = $arango->database->list;
ok(!grep(/$dbname/, @$res), "database does not exist");

done_testing();
