use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# Exercises the row state model documented in DBIx::QuickORM::Row,
# DBIx::QuickORM::Role::Row, and DBIx::QuickORM::Connection::RowData:
# stored vs pending vs inflated/raw views, save/discard/update/refresh,
# delete, the storage/validity predicates, the field-hash views, clone,
# and the primary-key helpers.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir  = tempdir(CLEANUP => 1);
my $file = "$dir/row_state.sqlite";
my $dsn  = "dbi:SQLite:dbname=$file";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE users (user_id INTEGER PRIMARY KEY, name TEXT NOT NULL, email TEXT, meta_json TEXT)');
    $dbh->do('INSERT INTO users (name, email, meta_json) VALUES (?, ?, ?)', undef, 'bob', 'bob@example.com', '{"age":42}');
    $dbh->disconnect;
}

# Read a column straight from the database, bypassing the ORM and any
# row cache, so we can verify what was actually persisted.
sub db_value {
    my ($col, $pk) = @_;
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    my ($val) = $dbh->selectrow_array("SELECT $col FROM users WHERE user_id = ?", undef, $pk);
    $dbh->disconnect;
    return $val;
}

my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn}, auto_types => ['JSON']);
isa_ok($con, ['DBIx::QuickORM::Connection'], "got a live Connection");

my $bob = $con->handle('users')->where({name => 'bob'})->one;
my $bob_pk = $bob->field('user_id');
ok(defined($bob_pk), "fetched bob and have a primary key");

subtest field_get_set_and_pending => sub {
    ok($bob->is_stored, "freshly fetched row is stored");
    ok($bob->in_storage, "freshly fetched row is in_storage");
    ok($bob->is_valid, "freshly fetched row is valid");
    ok(!$bob->is_invalid, "freshly fetched row is not invalid");
    ok(!$bob->has_pending, "no pending changes after fetch");

    is($bob->field('name'), 'bob', "field() returns the stored value");

    $bob->field(name => 'robert');
    ok($bob->has_pending, "setting a field stages a pending change");
    is($bob->field('name'), 'robert', "field() reflects the pending value");
    is($bob->stored_field('name'), 'bob', "stored_field() still shows the original db value");

    # Database is untouched until save.
    is(db_value(name => $bob_pk), 'bob', "database row unchanged before save");

    $bob->save;
    ok(!$bob->has_pending, "save() clears pending");
    is($bob->field('name'), 'robert', "value persists in the row after save");
    is(db_value(name => $bob_pk), 'robert', "save() wrote the change to the database");

    # Reset for later subtests.
    $bob->update({name => 'bob'});
    is(db_value(name => $bob_pk), 'bob', "reset name back to bob");
};

subtest modify_now_save_later => sub {
    $bob->field(name  => 'robert');
    $bob->field(email => 'r@example.com');
    ok($bob->has_pending, "multiple staged changes are pending together");
    is($bob->field('name'),  'robert',        "first pending change visible");
    is($bob->field('email'), 'r@example.com', "second pending change visible");
    is($bob->stored_field('name'),  'bob',             "stored name unchanged while pending");
    is($bob->stored_field('email'), 'bob@example.com', "stored email unchanged while pending");
    is(db_value(name  => $bob_pk), 'bob',             "db name unchanged while pending");
    is(db_value(email => $bob_pk), 'bob@example.com', "db email unchanged while pending");

    $bob->save;
    is(db_value(name  => $bob_pk), 'robert',        "both changes saved together (name)");
    is(db_value(email => $bob_pk), 'r@example.com', "both changes saved together (email)");

    $bob->update({name => 'bob', email => 'bob@example.com'});
};

subtest inflated_vs_raw_vs_stored => sub {
    is($bob->field('meta_json'),     {age => 42}, "field() inflates JSON to a ref");
    is($bob->raw_field('meta_json'), '{"age":42}', "raw_field() returns the raw db string");

    $bob->field(meta_json => {age => 43});
    is($bob->field('meta_json'),         {age => 43}, "pending inflated value");
    is($bob->pending_field('meta_json'), {age => 43}, "pending_field() shows pending value");
    is($bob->stored_field('meta_json'),  {age => 42}, "stored_field() inflates the original");
    is($bob->raw_stored_field('meta_json'), '{"age":42}', "raw_stored_field() shows original raw db value");
    like($bob->raw_pending_field('meta_json'), qr/"age"\s*:\s*43/, "raw_pending_field() deflates the pending value");

    $bob->discard;
    is($bob->field('meta_json'), {age => 42}, "discard() restores the stored value");
    ok(!$bob->has_pending, "discard() cleared pending");
};

subtest field_hash_views => sub {
    $bob->field(email => 'changed@example.com');

    my $fields = $bob->fields;
    is(ref($fields), 'HASH', "fields() returns a hashref");
    is($fields->{name},  'bob',                 "fields() merges stored name");
    is($fields->{email}, 'changed@example.com', "fields() merges pending email over stored");
    is($fields->{meta_json}, {age => 42}, "fields() inflates");

    my $raw = $bob->raw_fields;
    is(ref($raw), 'HASH', "raw_fields() returns a hashref");
    is($raw->{email}, 'changed@example.com', "raw_fields() includes pending value");
    is($raw->{meta_json}, '{"age":42}', "raw_fields() returns raw db string");

    my $stored = $bob->stored_fields;
    is($stored->{email}, 'bob@example.com', "stored_fields() shows original");

    my $pending = $bob->pending_fields;
    is($pending->{email}, 'changed@example.com', "pending_fields() shows only pending");
    ok(!exists $pending->{name}, "pending_fields() excludes unchanged fields");

    $bob->discard;
};

subtest update_discard_refresh => sub {
    $bob->update(email => 'updated@example.com');
    ok(!$bob->has_pending, "update() saves (no pending left)");
    is(db_value(email => $bob_pk), 'updated@example.com', "update() persisted the change");

    # update with a hashref form
    $bob->update({email => 'hashform@example.com'});
    is(db_value(email => $bob_pk), 'hashform@example.com', "update(\\%changes) persisted the change");

    # discard drops pending without saving
    $bob->field(name => 'temporary');
    ok($bob->has_pending, "pending change set");
    $bob->discard;
    ok(!$bob->has_pending, "discard() cleared pending");
    is($bob->field('name'), 'bob', "discard() reverts to stored value");

    # refresh re-reads from the db (mutate it underneath us)
    {
        my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
        $dbh->do('UPDATE users SET email = ? WHERE user_id = ?', undef, 'external@example.com', $bob_pk);
        $dbh->disconnect;
    }
    is($bob->field('email'), 'hashform@example.com', "row still has old value before refresh");
    $bob->refresh;
    is($bob->field('email'), 'external@example.com', "refresh() re-read the db value");

    # reset
    $bob->update({email => 'bob@example.com'});
};

subtest in_storage_and_validity => sub {
    # A vivified (not-yet-inserted) row is not in storage.
    my $new = $con->handle('users')->vivify({name => 'carol', email => 'carol@example.com'});
    ok(!$new->is_stored, "vivified row is not stored");
    ok(!$new->in_storage, "vivified row is not in_storage");
    ok($new->has_pending, "vivified row has pending data");

    $new->insert;
    ok($new->is_stored, "row is stored after insert");
    ok(!$new->has_pending, "insert clears pending");
    ok(defined($new->field('user_id')), "insert assigned a primary key");

    $new->delete;
};

subtest delete => sub {
    my $new = $con->handle('users')->insert({name => 'dave', email => 'dave@example.com'});
    ok($new->is_stored, "inserted dave is stored");
    my $dave_pk = $new->field('user_id');
    is(db_value(name => $dave_pk), 'dave', "dave present in db before delete");

    $new->delete;
    is(db_value(name => $dave_pk), undef, "delete() removed dave from the db");
};

subtest clone => sub {
    my $clone = $bob->clone(name => 'cloned');
    ok(!$clone->is_stored, "clone is a new unsaved row");
    ok(!defined($clone->field('user_id')), "clone drops the primary key");
    is($clone->field('name'),  'cloned',           "clone applied the name override");
    is($clone->field('email'), 'bob@example.com',  "clone carried over non-pk fields");

    # The clone's inflated json must be an independent copy.
    my $clone2 = $bob->clone;
    my $cmeta  = $clone2->field('meta_json');
    is($cmeta, {age => 42}, "clone carried the json field");
    $cmeta->{age} = 999;
    is($bob->field('meta_json'), {age => 42}, "mutating clone's json did not affect the original (dclone)");

    $clone->insert;
    ok($clone->is_stored, "clone can be inserted");
    my $clone_pk = $clone->field('user_id');
    ok(defined($clone_pk), "inserted clone got its own pk");
    isnt($clone_pk, $bob_pk, "clone's pk differs from the original");
    $clone->delete;
};

subtest primary_key_helpers => sub {
    is([$bob->primary_key_field_list], ['user_id'], "primary_key_field_list");
    is([$bob->primary_key_value_list], [$bob_pk], "primary_key_value_list");

    my %pkh = $bob->primary_key_hash;
    is(\%pkh, {user_id => $bob_pk}, "primary_key_hash");
    is($bob->primary_key_hashref, {user_id => $bob_pk}, "primary_key_hashref");
};

subtest field_validation => sub {
    like(dies { $bob->field('nonesuch') }, qr/does not have a 'nonesuch' field/, "field() croaks on unknown field");
    like(dies { $bob->field() }, qr/Must specify a field name/, "field() croaks without a field name");
    like(dies { $bob->has_field() }, qr/Must specify a field name/, "has_field() croaks without a field name");
    ok($bob->has_field('name'), "has_field() true for a real field");
    ok(!$bob->has_field('nope'), "has_field() false for a missing field");
    ok(!$bob->field_is_desynced('name'), "field_is_desynced() false for a synced field");
};

done_testing;
