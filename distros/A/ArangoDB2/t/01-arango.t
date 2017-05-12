use strict;
use warnings;

use Data::Dumper;
use Test::More;

use ArangoDB2;

my $res;

my $arango = ArangoDB2->new("http://localhost:8529", $ENV{ARANGO_USER}, $ENV{ARANGO_PASS});

# test required methods
my @methods = qw(
    admin
    database
    databases
    http
    uri
    version
);

for my $method (@methods) {
    can_ok($arango, $method);
}

# test for sub objects accessors
isa_ok($arango->admin, 'ArangoDB2::Admin');
isa_ok($arango->database, 'ArangoDB2::Database');
isa_ok($arango->endpoint, 'ArangoDB2::Endpoint');
isa_ok($arango->http, 'ArangoDB2::HTTP');
isa_ok($arango->uri, 'URI');

# skip tests against the actual ArangoDB2 server unless
# LIVE_TEST env param is set
if (!$ENV{LIVE_TEST}) {
    diag("Skipping live API tests - set LIVE_TEST=1 to enable");
    done_testing();
    exit;
}

# api methods
$res = $arango->version;
ok(defined $res->{version}, "version: version");
ok(defined $res->{server}, "version: server");

done_testing();
