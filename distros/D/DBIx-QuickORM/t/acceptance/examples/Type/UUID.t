# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/Type/UUID.pm. Whenever an example
# there changes, change its copy here to match: t/acceptance/Examples.t fails while any example has
# no copy in an example test.
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test::Examples;

do_for_pg {
    my ($db) = @_;
    $db->connect->do($SCHEMA);
    $db->connect->do("CREATE TABLE sessions (id UUID PRIMARY KEY, owner_uuid BYTEA)");
    my $orm = DBIx::QuickORM->new(connect => sub { $db->connect });

    # CREATE TABLE sessions (id UUID PRIMARY KEY, owner_uuid BYTEA)

    my $uuid    = '0190a6e8-1d2c-7c3b-9f00-123456789abc';
    my $session = $orm->insert(
        sessions => {
            id         => $uuid,
            owner_uuid => $uuid,
        },
    );

    my $sid   = $session->field('id');            # the string, from a native uuid column
    my $owner = $session->field('owner_uuid');    # the string, stored as 16 bytes

    my $fresh = $orm->insert(sessions => {owner_uuid => $uuid});    # id gets a new version 7 UUID

    like($fresh->field('id'), qr/^[0-9a-f]{8}-[0-9a-f]{4}-7/, "a left-out key gets a version 7 UUID");
    is($sid,                                      $uuid, "a native uuid column");
    is($owner,                                    $uuid, "a binary column named like a UUID");
    is(length($session->raw_field('owner_uuid')), 16,    "holds the 16 bytes");
};

done_testing;
