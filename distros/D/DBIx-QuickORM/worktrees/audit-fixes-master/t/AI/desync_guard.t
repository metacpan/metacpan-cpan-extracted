use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# Exercises desync detection and the save guard in DBIx::QuickORM::Row:
# a refresh that changes stored values underneath pending changes flags the
# affected fields, save() croaks while any flag remains (track_desync is on
# by default), and discard / force_sync / per-field update resolve it.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir  = tempdir(CLEANUP => 1);
my $file = "$dir/desync.sqlite";
my $dsn  = "dbi:SQLite:dbname=$file";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE people (person_id INTEGER PRIMARY KEY, name TEXT NOT NULL, email TEXT, age INTEGER)');
    $dbh->disconnect;
}

sub db_change {
    my ($pk, %set) = @_;
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do("UPDATE people SET $_ = ? WHERE person_id = ?", undef, $set{$_}, $pk) for keys %set;
    $dbh->disconnect;
}

sub db_value {
    my ($col, $pk) = @_;
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    my ($val) = $dbh->selectrow_array("SELECT $col FROM people WHERE person_id = ?", undef, $pk);
    $dbh->disconnect;
    return $val;
}

my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
my $h   = $con->handle('people');

sub desynced_row {
    my (%fields) = @_;
    my $row = $h->insert({name => 'sync', email => 'sync@example.com', age => 1, %fields});
    my $pk  = $row->field('person_id');

    $row->field(name => 'mine');
    db_change($pk, name => 'theirs');
    $row->refresh;

    return ($row, $pk);
}

subtest refresh_with_pending_flags_desync => sub {
    my ($row, $pk) = desynced_row();

    ok($row->is_desynced, "row is flagged as desynced");
    ok($row->field_is_desynced('name'), "the conflicted field is flagged");
    ok(!$row->field_is_desynced('email'), "untouched fields are not flagged");
    is($row->stored_field('name'), 'theirs', "stored view has the refreshed value");
    is($row->pending_field('name'), 'mine', "pending view kept the local edit");

    like(dies { $row->save }, qr/This row is out of sync/, "save() croaks on a desynced row");
    is(db_value(name => $pk), 'theirs', "database value untouched by the failed save");
};

subtest discard_resolves_desync => sub {
    my ($row, $pk) = desynced_row();

    $row->discard;
    ok(!$row->is_desynced, "discard cleared the desync flags");
    ok(!$row->has_pending, "discard cleared the pending data");
    is($row->field('name'), 'theirs', "row now reads the refreshed value");
    ok(lives { $row->save }, "save() is a no-op after discard");
};

subtest force_sync_then_save => sub {
    my ($row, $pk) = desynced_row();

    $row->force_sync;
    ok(!$row->is_desynced, "force_sync cleared the desync flags");
    ok($row->has_pending, "pending data is still staged");

    ok(lives { $row->save }, "save() works after force_sync");
    is(db_value(name => $pk), 'mine', "local edit overwrote the conflicting value");
};

subtest update_clears_desync_per_field => sub {
    my ($row, $pk) = desynced_row();

    ok(lives { $row->update({name => 'updated'}) }, "update() of the desynced field is an explicit overwrite");
    ok(!$row->is_desynced, "no desync flags remain");
    is(db_value(name => $pk), 'updated', "database has the updated value");
};

subtest update_of_other_field_still_croaks => sub {
    my ($row, $pk) = desynced_row();

    like(
        dies { $row->update({email => 'new@example.com'}) },
        qr/This row is out of sync/,
        "updating a different field croaks while another field is desynced",
    );
    is(db_value(email => $pk), 'sync@example.com', "database email unchanged");

    # Updating the conflicted field itself resolves the row.
    ok(lives { $row->update({name => 'resolved', email => 'new@example.com'}) }, "updating all desynced fields resolves the conflict");
    is(db_value(name  => $pk), 'resolved',         "name written");
    is(db_value(email => $pk), 'new@example.com', "email written");
};

subtest failed_update_does_not_arm_pending => sub {
    my ($row, $pk) = desynced_row();

    # update() of a non-desynced field must validate BEFORE staging, so a
    # croak leaves nothing armed; otherwise a later force_sync->save would
    # silently write the failed update's value.
    like(
        dies { $row->update({email => 'leak@example.com'}) },
        qr/This row is out of sync/,
        "update of a non-desynced field croaks while name is desynced",
    );
    ok(!defined $row->pending_field('email'), "the failed update did not arm email in pending");

    $row->force_sync;
    ok(lives { $row->save }, "save works after force_sync past the name desync");
    is(db_value(email => $pk), 'sync@example.com', "the failed update's email value did not leak to the database");
};

subtest update_unknown_field_croaks => sub {
    my $row = $h->insert({name => 'fields', age => 2});
    like(
        dies { $row->update({nope => 1}) },
        qr/This row does not have a 'nope' field/,
        "update() validates field names",
    );
};

done_testing;
