# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/Manual/Keys.pm. Whenever an
# example there changes, change its copy here to match: t/acceptance/Examples.t fails while any
# example has no copy in an example test.
use Test2::V0;
use lib 't/lib';

use DateTime;

use DBIx::QuickORM;
use DBIx::QuickORM::Value qw/inflated/;
use DBIx::QuickORM::Test::Examples;

my $V7 = qr/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/;

do_for_pg {
    my ($db) = @_;
    my ($dsn, $user, $pass) = ($db->connect_string, $db->username, $db->password);
    my $dbh = $db->connect;

    # PostgreSQL before 13 has no gen_random_uuid() without pgcrypto. A random version 4 UUID stands in for it.
    $dbh->do(q{CREATE FUNCTION gen_random_uuid() RETURNS uuid AS $$ SELECT overlay(md5(random()::text) placing '4' from 13 for 1)::uuid $$ LANGUAGE sql}) if $dbh->{pg_server_version} < 130000;
    $dbh->do(<<'    SQL');
    CREATE TABLE users (
        id          SERIAL PRIMARY KEY,
        name        TEXT NOT NULL,
        email       TEXT UNIQUE,
        prefs       JSON,
        referred_by INTEGER REFERENCES users (id),
        created     TIMESTAMP NOT NULL DEFAULT now()
    );

    CREATE TABLE posts (
        id      SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users (id),
        title   TEXT NOT NULL,
        views   INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE memberships (
        user_id INTEGER NOT NULL REFERENCES users (id),
        team    TEXT NOT NULL,
        role    TEXT,
        PRIMARY KEY (user_id, team)
    );

    CREATE TABLE sessions  (id UUID PRIMARY KEY, owner TEXT);
    CREATE TABLE events    (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), name TEXT);
    CREATE TABLE snapshots (taken TIMESTAMPTZ PRIMARY KEY, note TEXT);
    CREATE TABLE tokens    (token CHAR(36) PRIMARY KEY, note TEXT);
    SQL
    $dbh->disconnect;

    my $orm = DBIx::QuickORM->new(connect => sub { $db->connect });
    my $id  = $orm->insert(users => {name => 'Ann'})->field('id');

    # KEY FORMS
    my $ann = $orm->find(users => $id);    # a single value, for a single-field key
    $ann = $orm->find(users => [$id]);     # an arrayref of the values, in the key's declared order

    # a hashref of the key fields (other fields are ignored, so row data works)
    $ann = $orm->find(users => {id => $id});

    # a row object (or its row data): read Ann's row again
    my $fresh = $orm->find(
        users => $ann,
        cache => 0,
    );

    $orm->insert(
        memberships => {
            user_id => $id,
            team    => 'ops',
            role    => 'lead',
        }
    );

    my $member = $orm->find(
        memberships => {
            user_id => $id,     # a compound key
            team    => 'ops',
        }
    );

    $member = $orm->find(memberships => [$id, 'ops']);    # user_id, then team: the declared order
    my $pk = $member->pk;                                 # {user_id => $id, team => 'ops'}

    $orm->clear_cache(memberships => [$id, 'ops']);       # the same forms

    is($ann->field('name'), 'Ann', "every key form finds the row");
    ref_is($fresh->row_data, $ann->row_data, "a row object as the key reads its own row");
    is($member->field('role'), 'lead',                          "a compound key as a hashref or an arrayref");
    is($pk,                    {user_id => $id, team => 'ops'}, "pk gives the key fields");
    ok(!$member->is_canon, "clear_cache took the arrayref form");
    like(dies { $orm->find(memberships => $id) },              qr/compound primary key/,                         "a single value for a compound key croaks");
    like(dies { $orm->find(memberships => [$id]) },            qr/the arrayref holds 1 value/,                   "and an arrayref of the wrong length");
    like(dies { $orm->find(memberships => {user_id => $id}) }, qr/'team' of the table 'memberships' is missing/, "and a missing key field");

    # TYPED KEYS
    my $uuid    = '0190a6e8-1d2c-7c3b-9f00-123456789abc';
    my $session = $orm->insert(
        sessions => {
            id    => $uuid,
            owner => 'Ann',
        }
    );
    my $same = $orm->find(sessions => uc $uuid);    # the held row: a UUID key matches in upper or lower case

    my $taken = DateTime->new(
        year      => 2024,
        month     => 1,
        day       => 2,
        hour      => 3,
        time_zone => 'America/New_York',
    );
    my $snap = $orm->insert(
        snapshots => {
            taken => $taken,
            note  => 'nightly',
        }
    );
    # the held row: the same instant
    my $again = $orm->find(snapshots => $taken->clone->set_time_zone('UTC'));

    ref_is($same->row_data,  $session->row_data, "an upper-case UUID finds the held row");
    ref_is($again->row_data, $snap->row_data,    "a DateTime in another zone finds the held row");
    is($orm->find(sessions => uc $uuid, cache => 0)->field('owner'),                            'Ann',                        "the database takes the upper-case UUID too");
    is($orm->find(snapshots => $taken->clone->set_time_zone('UTC'), cache => 0)->field('note'), 'nightly',                    "and the DateTime in another zone");
    is($snap->field('taken')->datetime_ref->time_zone->name,                                    'UTC',                        "the key reads back in the ORM's zone");
    is($snap->field('taken')->datetime_ref->hour,                                               8,                            "as the same instant");
    is($orm->connection->db_map->table('sessions')->{fields}->{id}->{orm_type},                 'DBIx::QuickORM::Type::UUID', "a native uuid column gets the UUID type from the scan");
    is($orm->connection->db_map->table('tokens')->{fields}->{token}->{orm_type},                undef,                        "a CHAR(36) column does not");

    # THE FORMAT HINT
    my $legacy = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        types => {
            tokens => {
                token => {
                    class  => 'UUID',
                    format => sub { uc $_[0] },    # the table stores upper-case text
                },
            },
        },
    );

    my $token = $legacy->insert(
        tokens => {
            token => $uuid,
            note  => 'legacy',
        }
    );
    my $text  = $token->raw_field('token');    # '0190A6E8-1D2C-7C3B-9F00-123456789ABC', as stored
    my $found = $legacy->find(
        tokens => $uuid,
        cache  => 0,                           # the database gets the upper-case form too
    );

    is($text,                                                                             uc($uuid), "format upper-cases the value sent");
    is($found->field('note'),                                                             'legacy',  "and the key looked up");
    is($orm->find(tokens => $uuid, cache => 0),                                           undef,     "without the hint the lower-case text matches nothing");
    is($legacy->handle('tokens')->where({token => $uuid})->only,                          undef,     "a where sends its values as given: the lower-case text matches nothing");
    is($legacy->handle('tokens')->where({token => inflated($uuid)})->only->field('note'), 'legacy',  "inflated() deflates and formats it");
    my $default = DBIx::QuickORM->new(
        credentials  => {dsn    => $dsn, user => $user, pass => $pass},
        types        => {tokens => {token  => {class => 'UUID', format => sub { lc $_[0] }}}},
        type_options => {UUID   => {format => sub { uc $_[0] }}},
    );
    is($default->find(tokens => $uuid,     cache => 0), undef, "type_options sets the default format, and the field's own lower-casing format wins");
    is($default->find(tokens => uc($uuid), cache => 0), undef, "whatever case is given");
    is($default->find(tokens => uc($uuid), cache => 0, raw => 1)->field('note'), 'legacy', "a raw key bypasses the format");

    # GENERATED KEYS
    my $new = $orm->insert(sessions => {owner => 'Bob'});    # id left out: a new version 7 UUID
    my $id7 = $new->field('id');

    # the database fills id (gen_random_uuid), so the ORM leaves it alone
    my $event = $orm->insert(events => {name => 'start'});

    like($id7, $V7, "a UUID key left out is generated, version 7");
    is($orm->find(sessions => $id7, cache => 0)->field('owner'), 'Bob', "and stored");
    unlike($event->field('id'), $V7, "a key the database fills is left to it");
    ok($event->field('id'), "and read back");
    like(dies { $orm->insert(snapshots => {note => 'no key'}) }, object { call kind => 'not_null_violation' }, "a DateTime key is never generated");

    my $v7_only = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        # always generate, even over the database default
        types => {events => {id => {generate => 'prefer_orm'}}},
    );
    my $forced = $v7_only->insert(events => {name => 'forced'});

    my $never = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        type_options => {UUID => {generate => 'none'}},    # never generate, for every UUID field
    );
    # the database rejects the missing key
    my $ok = eval { $never->insert(sessions => {owner => 'Cy'}); 1 };

    like($forced->field('id'), $V7, "prefer_orm generates over the database default");
    ok(!$ok, "none never generates");
    is($@->kind, 'not_null_violation', "so the database rejects the missing key");
    my $given = '0191a6e8-1d2c-7c3b-9f00-123456789abc';
    is($never->insert(sessions => {id => $given, owner => 'Di'})->field('id'), $given, "a given value always wins");
};

done_testing;
