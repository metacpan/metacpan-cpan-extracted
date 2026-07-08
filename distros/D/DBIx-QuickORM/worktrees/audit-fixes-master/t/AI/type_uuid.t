use Test2::V0 '!meta', '!pass';

# Coverage for DBIx::QuickORM::Type::UUID: inflate/deflate, string vs binary
# affinity, looks_like_uuid / looks_like_bin, ->new returning a v7 UUID,
# autotype registration (including substring name matching), and a real
# round-trip through a SQLite "uuid" column.

BEGIN {
    skip_all "UUID is required for these tests"
        unless eval { require UUID; 1 };
}

use DBIx::QuickORM::Type::UUID;

my $C = 'DBIx::QuickORM::Type::UUID';

my $SAMPLE = '019e5e0b-fd7d-7211-990b-4805a88dc096';

subtest new_returns_v7_uuid => sub {
    my $u = $C->new;
    like($u, qr/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i, "->new returns a hyphenated UUID string");

    # Version nibble (first char of 3rd group) is 7 for a v7 UUID.
    my @groups = split /-/, $u;
    is(substr($groups[2], 0, 1), '7', "->new returns a v7 UUID (version nibble is 7)");

    isnt($C->new, $C->new, "->new returns a distinct value each call");
};

subtest looks_like => sub {
    is($C->looks_like_uuid($SAMPLE), $SAMPLE, "looks_like_uuid returns the canonical string for a UUID");
    is($C->looks_like_uuid(uc $SAMPLE), $SAMPLE, "looks_like_uuid canonicalizes to lowercase");
    is($C->looks_like_uuid('not-a-uuid'), undef, "looks_like_uuid returns undef for a non-UUID");
    is($C->looks_like_uuid(''), undef, "looks_like_uuid returns undef for empty string");

    # Function form (no invocant): a single argument IS the value. These are
    # deliberate dual-call helpers (they take the value via pop), so they must
    # work both as $class->looks_like_uuid($v) and as looks_like_uuid($v).
    # This guards against "fixing" them into shift-based methods, which would
    # break every function-form caller.
    no warnings 'once';
    is(DBIx::QuickORM::Type::UUID::looks_like_uuid($SAMPLE), $SAMPLE, "looks_like_uuid works called as a plain function (no invocant)");
    is(DBIx::QuickORM::Type::UUID::looks_like_uuid(uc $SAMPLE), $SAMPLE, "function-form looks_like_uuid canonicalizes to lowercase");
    is(DBIx::QuickORM::Type::UUID::looks_like_uuid('not-a-uuid'), undef, "function-form looks_like_uuid returns undef for a non-UUID");

    my $bin;
    UUID::parse($SAMPLE, $bin);
    {
        use bytes;
        is(length($bin), 16, "packed UUID is 16 bytes");
    }
    is($C->looks_like_bin($bin), $SAMPLE, "looks_like_bin unparses 16 bytes back to the canonical string");
    is($C->looks_like_bin('short'), undef, "looks_like_bin returns undef for non-16-byte input");
    is(DBIx::QuickORM::Type::UUID::looks_like_bin($bin), $SAMPLE, "looks_like_bin works called as a plain function (no invocant)");
    is(DBIx::QuickORM::Type::UUID::looks_like_bin('short'), undef, "function-form looks_like_bin returns undef for non-16-byte input");
};

subtest affinity => sub {
    is($C->qorm_affinity(sql_type => 'uuid'), 'string', "native uuid sql_type -> string affinity");
    is($C->qorm_affinity(sql_type => 'UUID'), 'string', "uuid sql_type match is case-insensitive");
    is($C->qorm_affinity(sql_type => 'BLOB'),    'binary', "blob sql_type -> binary affinity");
    is($C->qorm_affinity(sql_type => 'binary'),  'binary', "binary sql_type -> binary affinity");
    is($C->qorm_affinity(sql_type => 'bytea'),   'binary', "bytea sql_type -> binary affinity");
    is($C->qorm_affinity, 'string', "default affinity is string");

    my $mock_dialect = mock {} => (
        add => [supports_type => sub { my (undef, $t) = @_; return $t eq 'uuid' ? 'UUID' : undef }],
    );
    is($C->qorm_affinity(dialect => $mock_dialect), 'string', "dialect supporting uuid -> string affinity");
};

subtest inflate => sub {
    is($C->qorm_inflate(class => $C, value => $SAMPLE), $SAMPLE, "inflate of a UUID string returns the canonical string");
    is($C->qorm_inflate(class => $C, value => undef), undef, "undef inflates to undef");

    my $bin;
    UUID::parse($SAMPLE, $bin);
    is($C->qorm_inflate(class => $C, value => $bin), $SAMPLE, "inflate of packed bytes returns the canonical string");

    like(
        dies { $C->qorm_inflate(class => $C, value => 'garbage') },
        qr/does not look like a UUID/i,
        "inflate croaks on a value that is neither a UUID string nor 16 bytes",
    );
};

subtest deflate => sub {
    is(
        $C->qorm_deflate(class => $C, value => $SAMPLE, affinity => 'string'),
        $SAMPLE,
        "string affinity deflates a UUID to the hyphenated form",
    );

    my $bin = $C->qorm_deflate(class => $C, value => $SAMPLE, affinity => 'binary');
    {
        use bytes;
        is(length($bin), 16, "binary affinity deflates a UUID to 16 packed bytes");
    }
    is($C->looks_like_bin($bin), $SAMPLE, "the packed bytes round-trip back to the original UUID");

    # Passing already-binary data through each affinity.
    is($C->qorm_deflate(class => $C, value => $bin, affinity => 'binary'), $bin, "binary value stays binary for binary affinity");
    is($C->qorm_deflate(class => $C, value => $bin, affinity => 'string'), $SAMPLE, "binary value deflates to a string for string affinity");

    is($C->qorm_deflate(class => $C, value => undef, affinity => 'string'), undef, "undef deflates to undef");

    like(
        dies { $C->qorm_deflate(class => $C, value => $SAMPLE) },
        qr/Could not determine affinity/,
        "deflate croaks without an affinity",
    );

    like(
        dies { $C->qorm_deflate(class => $C, value => 'garbage', affinity => 'string') },
        qr/does not look like a uuid/i,
        "deflate croaks on a non-UUID value",
    );
};

subtest compare => sub {
    # qorm_compare follows the equality contract: true when the values are the
    # same, false when they differ.
    ok($C->qorm_compare($SAMPLE, $SAMPLE), "identical UUID strings compare equal");
    ok($C->qorm_compare(undef, undef), "two undefs compare equal");
    ok(!$C->qorm_compare($SAMPLE, undef), "defined vs undef compares unequal");
    ok(!$C->qorm_compare($SAMPLE, $C->new), "different UUIDs compare unequal");

    # A UUID inflated from packed bytes is lowercase (UUID::unparse is
    # canonical lowercase), so it compares equal to the lowercase string form.
    my $bin;
    UUID::parse($SAMPLE, $bin);
    ok($C->qorm_compare($SAMPLE, $bin), "string and packed-binary forms of the same UUID compare equal");

    # Inflation canonicalizes to lowercase, so the same UUID written in upper
    # vs lower case compares equal.
    ok($C->qorm_compare($SAMPLE, uc $SAMPLE), "differing case compares equal (canonical lowercase)");

    ok($C->qorm_compare('not-a-uuid', 'not-a-uuid'), "identical invalid values compare equal without croaking");
    ok(!$C->qorm_compare('not-a-uuid', 'also-not-a-uuid'), "different invalid values compare unequal without croaking");
};

subtest autotype_registration => sub {
    my (%types, %affinities);
    $C->qorm_register_type(\%types, \%affinities);

    is($types{uuid}, $C, "registers itself for the 'uuid' SQL type");

    ok($affinities{string} && @{$affinities{string}}, "registers a string-affinity name matcher");
    ok($affinities{binary} && @{$affinities{binary}}, "registers a binary-affinity name matcher");

    # Substring name matching: any column whose name contains "uuid".
    my $matches = sub {
        my ($list, $name) = @_;
        for my $m (@$list) {
            my $r = $m->(name => $name, db_name => $name);
            return $r if $r;
        }
        return undef;
    };

    for my $name (qw/uuid user_uuid uuid_pk MetaUUID/) {
        is($matches->($affinities{binary}, $name), $C, "binary matcher claims column named '$name'");
        is($matches->($affinities{string}, $name), $C, "string matcher claims column named '$name'");
    }

    is($matches->($affinities{string}, 'name'), undef, "matcher does not claim an unrelated column name");

    # Does not clobber an existing claim.
    my %pre = (uuid => 'Pre::Existing');
    $C->qorm_register_type(\%pre, {});
    is($pre{uuid}, 'Pre::Existing', "existing 'uuid' type claim is not clobbered");
};

subtest round_trip_through_sqlite => sub {
    skip_all "DBD::SQLite is required for the integration test"
        unless eval { require DBD::SQLite; 1 };

    require DBI;
    require File::Temp;
    require DBIx::QuickORM;

    my $dir  = File::Temp::tempdir(CLEANUP => 1);
    my $file = "$dir/uuid.sqlite";
    my $dsn  = "dbi:SQLite:dbname=$file";

    {
        my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
        # "user_uuid" exercises substring name matching; SQLite gives it TEXT
        # affinity, so deflation uses the string form.
        $dbh->do('CREATE TABLE accounts (account_id INTEGER PRIMARY KEY, label TEXT, user_uuid TEXT)');
        $dbh->do('INSERT INTO accounts (label, user_uuid) VALUES (?, ?)', undef, 'seed', $SAMPLE);
        $dbh->disconnect;
    }

    my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn}, auto_types => ['UUID']);

    my ($seed) = $con->handle('accounts')->all;
    is($seed->field('user_uuid'), $SAMPLE, "substring-named *uuid* column auto-typed and inflated");

    my $fresh = $C->new;
    my $new = $con->handle('accounts')->insert({label => 'fresh', user_uuid => $fresh});
    is($new->field('user_uuid'), $fresh, "UUID round-tripped on insert");

    # Read back from a fresh connection.
    my $con2 = DBIx::QuickORM->quick(credentials => {dsn => $dsn}, auto_types => ['UUID']);
    my ($fetched) = $con2->handle('accounts')->where({label => 'fresh'})->all;
    is($fetched->field('user_uuid'), $fresh, "stored UUID read back from a new connection");

    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    my ($raw) = $dbh->selectrow_array('SELECT user_uuid FROM accounts WHERE label = ?', undef, 'fresh');
    $dbh->disconnect;
    is($raw, $fresh, "raw stored value is the hyphenated UUID string for a TEXT column");
};

done_testing;
