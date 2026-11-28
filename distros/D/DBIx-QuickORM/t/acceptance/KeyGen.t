# Test origin: AI
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test;

my $FIXED = '00000000-0000-4000-8000-000000000001';
my $V7    = qr/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/;

my %BINARY = (PostgreSQL => 'BYTEA', MySQL => 'BINARY(16)', MariaDB => 'BINARY(16)', SQLite => 'BLOB', DuckDB => 'BLOB');

sub build_schema {
    my ($dbh, $family) = @_;
    my $bin = $BINARY{$family};
    $dbh->do($_)
        for (
        "CREATE TABLE text_keys (key_uuid VARCHAR(36) NOT NULL PRIMARY KEY, name VARCHAR(20))",
        "CREATE TABLE bin_keys (key_uuid $bin NOT NULL PRIMARY KEY, name VARCHAR(20))",
        "CREATE TABLE def_keys (key_uuid VARCHAR(36) NOT NULL PRIMARY KEY DEFAULT '$FIXED', name VARCHAR(20))",
        "CREATE TABLE pair_keys (key_uuid VARCHAR(36) NOT NULL, n INTEGER NOT NULL, PRIMARY KEY (key_uuid, n))",
        );
}

do_for_all_dbs {
    my ($db, $set) = @_;
    my $family = $set->{family};

    my $dbh = $db->connect;
    build_schema($dbh, $family);

    my $orm  = DBIx::QuickORM->new(dbh => $dbh, row_class => undef);
    my $keys = sub { [map { $_->[0] } @{$dbh->selectall_arrayref("SELECT key_uuid FROM $_[0] ORDER BY name")}] };
    my $hex  = sub { my $u = unpack('H*', $_[0]); join '-' => unpack('A8 A4 A4 A4 A12', $u) };

    subtest text => sub {
        my $row = $orm->insert(text_keys => {name => 'a'}, data => 1);
        like($row->{key_uuid}, $V7, "A left-out UUID key gets a version 7 UUID");
        is($keys->('text_keys'), [$row->{key_uuid}], "which is what the database holds");

        my $given = $orm->insert(text_keys => {name => 'b'}, as_given => 1, data => 1);
        like($given->{key_uuid}, $V7, "as_given includes the generated value");

        $orm->insert_many(text_keys => [{name => 'c'}, {name => 'd'}]);
        my @all = @{$keys->('text_keys')};
        like($_, $V7, "insert_many generates one per row") for @all[2, 3];
        isnt($all[2], $all[3], "each a new one");

        $orm->insert(text_keys => {key_uuid => $FIXED, name => 'e'});
        is($keys->('text_keys')->[4], $FIXED, "A given value wins");
    };

    subtest binary => sub {
        my $row = $orm->insert(bin_keys => {name => 'a'}, data => 1);
        is(length($row->{key_uuid}), 16, "A binary key gets 16 bytes");
        like($hex->($keys->('bin_keys')->[0]), $V7, "of a version 7 UUID");

        $orm->insert_many(bin_keys => [{name => 'b'}, {name => 'c'}], raw => 1);
        like($hex->($_), $V7, "insert_many too, deflated even with raw") for @{$keys->('bin_keys')}[1, 2];
    };

    subtest database_default => sub {
        $orm->insert(def_keys => {name => 'a'});
        if ($orm->connection->dialect->supports_returning_insert) {
            is($keys->('def_keys'), [$FIXED], "prefer_db leaves a column with a default to the database");
        }
        else {
            like($keys->('def_keys')->[0], $V7, "prefer_db generates without RETURNING, which could not read the default back");
        }

        my $prefer_orm = DBIx::QuickORM->new(dbh => $dbh, row_class => undef, types => {def_keys => {key_uuid => {generate => 'prefer_orm'}}});
        $prefer_orm->insert(def_keys => {name => 'b'});
        like($keys->('def_keys')->[1], $V7, "prefer_orm overrides the default");

        my $none = DBIx::QuickORM->new(dbh => $dbh, row_class => undef, type_options => {UUID => {generate => 'none'}});
        $dbh->do("DELETE FROM def_keys");
        $none->insert(def_keys => {name => 'c'});
        is($keys->('def_keys'), [$FIXED], "none leaves it to the database");
        ok(dies { $none->insert(text_keys => {name => 'z'}) }, "which errors when it cannot fill it");
    };

    subtest expression_default => sub {
        my $vnum = 0;
        if ($family =~ m/^(?:MySQL|MariaDB)\z/ && $dbh->selectrow_array("SELECT VERSION()") =~ m/^(\d+)\.(\d+)\.(\d+)/) {
            $vnum = sprintf('%d%03d%03d', $1, $2, $3);
        }

        my $ddl;
        if ($family eq 'MySQL') {
            skip_all "Expression defaults need MySQL 8.0.13" if $vnum < 8000013;
            $ddl = "key_uuid BINARY(16) NOT NULL PRIMARY KEY DEFAULT (uuid_to_bin(uuid()))";
        }
        elsif ($family eq 'MariaDB') {
            skip_all "Expression defaults need MariaDB 10.2.1" if $vnum < 10002001;
            $ddl = "key_uuid CHAR(36) NOT NULL PRIMARY KEY DEFAULT (uuid())";
        }
        elsif ($family eq 'PostgreSQL') {
            $ddl = q{key_uuid VARCHAR(36) NOT NULL PRIMARY KEY DEFAULT (regexp_replace(md5(random()::text), '^(.{12}).(.{3}).', '\\14\\28')::uuid::text)};
        }
        else {
            skip_all "Covered for MySQL, MariaDB, and PostgreSQL";
        }

        $dbh->do("CREATE TABLE expr_keys ($ddl, name VARCHAR(20))");
        my $exp = DBIx::QuickORM->new(dbh => $dbh, row_class => undef);
        my $row = $exp->insert(expr_keys => {name => 'a'}, data => 1);
        my $db  = $keys->('expr_keys')->[0];

        if ($family eq 'MySQL') {
            is($row->{key_uuid}, $db, "Without RETURNING, prefer_db generates over a default it could not read back");
            like($hex->($db), $V7, "a version 7 UUID from the ORM");
        }
        else {
            is($row->{key_uuid}, $db, "With RETURNING, prefer_db leaves the default to the database and reads it back");
            unlike($db, $V7, "not a version 7 UUID from the ORM");
        }
    };

    subtest compound => sub {
        $orm->insert(pair_keys => {n => 1});
        like($dbh->selectrow_array("SELECT key_uuid FROM pair_keys WHERE n = 1"), $V7, "The typed part of a compound key is generated");
    };

    subtest refused => sub {
        skip_all "GENERATED ALWAYS AS IDENTITY needs PostgreSQL 10" unless $family eq 'PostgreSQL' && $dbh->{pg_server_version} >= 100000;
        $dbh->do("CREATE TABLE ident_keys (id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY)");
        like(
            dies { DBIx::QuickORM->new(dbh => $dbh, types => {ident_keys => {id => {class => 'UUID', generate => 'prefer_orm'}}}) },
            qr/^The primary key field 'id' of the table 'ident_keys' has generate => 'prefer_orm', but the database refuses values for it/,
            "prefer_orm on GENERATED ALWAYS croaks when the map is built",
        );
    };
};

done_testing;
