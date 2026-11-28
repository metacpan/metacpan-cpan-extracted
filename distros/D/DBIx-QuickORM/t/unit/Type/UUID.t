# Test origin: AI
use Test2::V0;

use DBI;
use DBIx::QuickORM;
use DBIx::QuickORM::Type::UUID;
use DBIx::QuickORM::Value qw/sql/;

my $T    = 'DBIx::QuickORM::Type::UUID';
my $UUID = '0190a6e8-1d2c-7c3b-9f00-123456789abc';
my $BIN  = pack('H*', '0190a6e81d2c7c3b9f00123456789abc');

my %TEXT   = (affinity => 'string');
my %BINARY = (affinity => 'binary', size => 16);

subtest claims => sub {
    is([$T->base_types], ['uuid'], "Base type");
    ok($T->matches($_,  \%TEXT), "'$_' matches by name") for qw/uuid owner_uuid uuid_owner a_uuid_b USER_UUID/;
    ok(!$T->matches($_, \%TEXT), "'$_' does not")        for qw/uuids xuuid myuuid id/;

    ok($T->matches(owner_uuid  => {affinity => 'string', size => 36}), "A string sized for one");
    ok($T->matches(owner_uuid  => \%BINARY),                           "16 bytes");
    ok($T->matches(owner_uuid  => {affinity => 'binary'}),             "Binary with no size");
    ok(!$T->matches(uuid_count => {affinity => 'numeric'}),            "uuid_count int is not a UUID");
    ok(!$T->matches(owner_uuid => {affinity => 'string', size => 10}), "nor is a string too short");
    ok(!$T->matches(owner_uuid => {affinity => 'binary', size => 32}), "or binary of another size");
    ok(!$T->matches(owner_uuid => {affinity => 'boolean'}),            "or a boolean");
};

subtest convert => sub {
    is($T->deflate($UUID, \%BINARY),     $BIN,  "A binary field stores 16 bytes");
    is($T->inflate($BIN, \%BINARY),      $UUID, "which inflate to the lowercase string");
    is($T->deflate(uc($UUID), \%BINARY), $BIN,  "Upper case deflates too");

    is($T->deflate($UUID, \%TEXT), $UUID, "A text field stores the string as given");
    is($T->inflate($UUID, \%TEXT), $UUID, "and reads it as stored");
    ok($T->inflate_is_identity(\%TEXT),    "so inflate is the identity for a text field");
    ok(!$T->inflate_is_identity(\%BINARY), "but not for a binary one");

    ok($T->is_inflated($UUID),              "The string is inflated");
    ok(!$T->is_inflated($BIN),              "16 bytes are not");
    ok(!$T->is_inflated('abc'),             "nor is other text");
    ok($T->inflated_is_immutable_for_cache, "Inflated UUIDs are immutable strings, so rows hand out the cached value");

    my $new = $T->generate_key_value(\%BINARY);
    like($new, qr/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/, "A generated key is a lowercase version 7 UUID string");
    isnt($T->generate_key_value(\%BINARY), $new, "and a new one each time");
    is(length($T->deflate($new, \%BINARY)), 16, "which deflates to 16 bytes for a binary field");

    like(dies { $T->deflate('abc', \%BINARY) },                                  qr/^'abc' is not a UUID/,               "Anything else croaks for a binary field");
    like(dies { $T->deflate([],    \%TEXT) },                                    qr/is not a UUID/,                      "A reference croaks for any field");
    like(dies { $T->deflate('abc', {%BINARY, table => 'users', name => 'id'}) }, qr/^'abc' is not a UUID for users\.id/, "naming the field when its record names it");

    like(dies { $T->inflate('short', {%BINARY, table => 'users', name => 'id'}) }, qr/^A binary UUID must be 16 bytes, got 5 for users\.id/, "Inflating fewer than 16 bytes croaks, naming the field");
    like(dies { $T->inflate($UUID,   \%BINARY) },                                  qr/^A binary UUID must be 16 bytes, got 36/,              "and so does more, such as the text form in a binary column");
};

subtest missing_keys => sub {
    my $warnings = warnings {
        ok(!$T->matches(owner_uuid => {}), "A record with no affinity is not claimed by name");
        is($T->inflate($UUID, {}), $UUID, "inflate returns the value as stored");
        ok($T->inflate_is_identity({}), "which is the identity");
        is($T->deflate($UUID, {}), $UUID, "deflate sends it as given");
    };
    is($warnings, [], "A field record missing its keys gives no warnings");

    my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
    $dbh->do("CREATE TABLE t (id INTEGER PRIMARY KEY, created DATETIME, u CHAR(36))");
    $dbh->do("INSERT INTO t (created, u) VALUES ('2024-07-01 04:05:06', '$UUID')");
    my $orm = DBIx::QuickORM->new(dbh => $dbh);
    my $row;
    $warnings = warnings {
        $row = $orm->handle('t')->fields({
            x => {sql => sql('MAX(created)'), type => 'DateTime'},
            y => {sql => sql('MAX(u)'),       type => 'UUID'},
        })->only;
        $row->field($_) for qw/x y/;
    };
    is($warnings,        [],    "Typed sql() columns with no db_type read without warnings");
    is($row->field('y'), $UUID, "and the UUID reads as stored");
};

subtest canonical_key_value => sub {
    is($T->canonical_key_value($UUID),                $UUID,                "Lowercase text is the key");
    is($T->canonical_key_value(uc $UUID),             $UUID,                "upper case is lowercased");
    is($T->canonical_key_value(uc($UUID) =~ s/-//gr), uc($UUID) =~ s/-//gr, "32 hex digits are left as given, since nothing converts them for the database");
    is($T->canonical_key_value($BIN),                 $UUID,                "16 bytes become the string");
    is($T->canonical_key_value('abc'),                'abc',                "anything else is left as given");
};

subtest through_the_orm => sub {
    my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
    $dbh->do("CREATE TABLE ids (id BINARY(16) PRIMARY KEY, ident UUID, owner_uuid CHAR(36), uuid_count INTEGER)");
    my $orm = DBIx::QuickORM->new(dbh => $dbh, row_class => undef);

    is($orm->db_map->field(ids  => $_)->{orm_type}, $T, "'$_' is autotyped") for qw/ident owner_uuid/;
    ok(!$orm->db_map->field(ids => $_)->{orm_type}, "'$_' is not")           for qw/id uuid_count/;

    $orm = DBIx::QuickORM->new(dbh => $dbh, row_class => undef, types => {ids => {id => 'UUID'}});
    my $row = $orm->insert(ids => {id => $UUID, ident => $UUID});
    is($row->{id}, $BIN, "A UUID string going to a binary field is deflated to its bytes");
    ref_is($orm->refresh_row('ids', {id => $UUID}), $row, "and so is the primary key of a lookup");

    $dbh->do("CREATE TABLE texts (uuid CHAR(36) PRIMARY KEY)");
    $orm = DBIx::QuickORM->new(dbh => $dbh);
    my $held = $orm->insert(texts => {uuid => $UUID});
    my $hex  = $UUID =~ s/-//gr;
    is($orm->find(texts => $hex),             undef, "A key given as 32 hex digits does not find the held row");
    is($orm->find(texts => $hex, cache => 0), undef, "just as the database does not");
};

done_testing;
