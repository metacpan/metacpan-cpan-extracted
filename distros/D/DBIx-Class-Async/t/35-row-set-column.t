#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use lib 'lib';

BEGIN {
    eval { require DBD::SQLite; 1 }
        or plan skip_all => 'DBD::SQLite required for testing';
}

use TestSchema;
use DBIx::Class::Async::Schema;

# Setup test database
my $dbfile = 't/test_set_column.db';
unlink $dbfile if -e $dbfile;

# Create and deploy schema
my $schema = TestSchema->connect("dbi:SQLite:dbname=$dbfile");
$schema->deploy;

# Create async schema
my $async_schema = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$dbfile",
    undef,
    undef,
    { sqlite_unicode => 1 },
    { workers => 2, schema_class => 'TestSchema' }
);

# Create test user
my $user = $schema->resultset('User')->create({
    name   => 'Alice',
    email  => 'alice@example.com',
    active => 1,
});

subtest 'set_column - basic functionality' => sub {
    plan tests => 3;

    my $row = $async_schema->resultset('User')->find($user->id)->get;

    my $result = $row->set_column('name', 'Bob');

    is($result, 'Bob', 'Returns the value that was set');
    is($row->get_column('name'), 'Bob', 'Column value is updated');
    ok($row->is_column_changed('name'), 'Column is marked as dirty');
};

subtest 'set_column - marks dirty only if changed' => sub {
    plan tests => 4;

    my $row = $async_schema->resultset('User')->find($user->id)->get;

    # Set to same value
    $row->set_column('name', 'Alice');
    ok(!$row->is_column_changed('name'),
        'Column not dirty when set to same value');

    # Set to different value
    $row->set_column('name', 'Bob');
    ok($row->is_column_changed('name'),
        'Column is dirty when changed');

    # Set again to different value
    $row->set_column('name', 'Carol');
    ok($row->is_column_changed('name'),
        'Column remains dirty after another change');

    is($row->get_column('name'), 'Carol',
        'Column has the latest value');
};

subtest 'set_column - with undef' => sub {
    plan tests => 4;

    my $row = $async_schema->resultset('User')->find($user->id)->get;

    # Set to undef
    $row->set_column('email', undef);
    ok($row->is_column_changed('email'), 'Setting to undef marks as dirty');
    ok(!defined $row->get_column('email'), 'Value is undef');

    # Set undef to undef (no change)
    $row->set_column('email', undef);
    # Should still be dirty from first change
    ok($row->is_column_changed('email'), 'Column still dirty');

    # Set back to value
    $row->set_column('email', 'newemail@example.com');
    is($row->get_column('email'), 'newemail@example.com',
        'Can set back to a value');
};

subtest 'set_column - persists with update' => sub {
    plan tests => 3;

    my $row = $async_schema->resultset('User')->find($user->id)->get;

    $row->set_column('name', 'UpdatedName');
    $row->set_column('email', 'updated@example.com');

    ok($row->is_column_changed('name'), 'Name is dirty before update');

    # Update to database using dirty columns
    my %dirty = $row->get_dirty_columns;
    $row->update(\%dirty)->get;

    # Verify in database
    my $fresh = $schema->resultset('User')->find($user->id);
    is($fresh->name, 'UpdatedName', 'Name persisted to database');
    is($fresh->email, 'updated@example.com', 'Email persisted to database');
};

subtest 'set_columns - multiple columns' => sub {
    plan tests => 5;

    my $row = $async_schema->resultset('User')->find($user->id)->get;

    my $result = $row->set_columns({
        name   => 'MultiSet',
        email  => 'multiset@example.com',
        active => 0,
    });

    is($result, $row, 'Returns the row object (for chaining)');
    is($row->get_column('name'), 'MultiSet', 'Name was set');
    is($row->get_column('email'), 'multiset@example.com', 'Email was set');
    is($row->get_column('active'), 0, 'Active was set');

    ok($row->is_column_changed('name'), 'Columns are marked dirty');
};

subtest 'set_columns - chaining with update' => sub {
    plan tests => 4;

    my $row = $async_schema->resultset('User')->find($user->id)->get;

    # Get current active value (whatever it is)
    my $original_active = $row->get_column('active');

    # Chain set_columns with update
    my $changes = {
        name  => 'ChainedSet',
        email => 'chained@example.com',
    };
    $row->set_columns($changes)->update($changes)->get;

    # Verify
    my $fresh = $schema->resultset('User')->find($user->id);
    is($fresh->name, 'ChainedSet', 'Chained update worked');
    is($fresh->email, 'chained@example.com', 'All columns updated');
    is($fresh->active, $original_active, 'Unchanged columns preserved');

    # Verify active was NOT marked as dirty
    ok(!$row->is_column_changed('active'), 'Unchanged column not marked dirty');
};

subtest 'get_dirty_columns - list context' => sub {
    plan tests => 3;

    my $row = $async_schema->resultset('User')->find($user->id)->get;

    $row->set_column('name', 'DirtyTest');
    $row->set_column('email', 'dirty@example.com');

    my %dirty = $row->get_dirty_columns;

    is($dirty{name}, 'DirtyTest', 'Name in dirty columns');
    is($dirty{email}, 'dirty@example.com', 'Email in dirty columns');
    ok(!exists $dirty{active}, 'Unchanged columns not in dirty');
};

subtest 'get_dirty_columns - scalar context' => sub {
    plan tests => 2;

    my $row = $async_schema->resultset('User')->find($user->id)->get;

    $row->set_column('name', 'ScalarTest');

    my $dirty = $row->get_dirty_columns;

    isa_ok($dirty, 'HASH', 'Returns hashref in scalar context');
    is($dirty->{name}, 'ScalarTest', 'Contains dirty column');
};

subtest 'is_column_changed - check dirty status' => sub {
    plan tests => 4;

    my $row = $async_schema->resultset('User')->find($user->id)->get;

    ok(!$row->is_column_changed('name'), 'Fresh row has no dirty columns');

    $row->set_column('name', 'ChangedName');
    ok($row->is_column_changed('name'), 'Changed column is dirty');

    ok(!$row->is_column_changed('email'), 'Unchanged column is not dirty');

    $row->set_column('email', 'changed@example.com');
    ok($row->is_column_changed('email'), 'Newly changed column is dirty');
};

subtest 'make_column_dirty - force dirty' => sub {
    plan tests => 3;

    my $row = $async_schema->resultset('User')->find($user->id)->get;

    ok(!$row->is_column_changed('name'), 'Column starts clean');

    $row->make_column_dirty('name');
    ok($row->is_column_changed('name'), 'Column is now dirty');

    # Chaining
    my $result = $row->make_column_dirty('email');
    is($result, $row, 'Returns row for chaining');
};

subtest 'discard_changes - reload from database' => sub {
    plan tests => 4;

    my $row = $async_schema->resultset('User')->find($user->id)->get;

    my $original_name = $row->name;

    # Make changes
    $row->set_column('name', 'TemporaryName');
    $row->set_column('email', 'temp@example.com');

    ok($row->is_column_changed('name'), 'Column is dirty');
    is($row->get_column('name'), 'TemporaryName', 'Has temporary value');

    # Discard changes
    $row->discard_changes->get;

    ok(!$row->is_column_changed('name'), 'Dirty flag cleared');
    is($row->get_column('name'), $original_name, 'Value restored from database');
};

subtest 'discard_changes - clears all dirty columns' => sub {
    plan tests => 3;

    my $row = $async_schema->resultset('User')->find($user->id)->get;

    $row->set_column('name', 'Temp1');
    $row->set_column('email', 'temp2@example.com');
    $row->set_column('active', 0);

    my %dirty_before = $row->get_dirty_columns;
    ok(keys %dirty_before > 0, 'Has dirty columns before discard');

    $row->discard_changes->get;

    my %dirty_after = $row->get_dirty_columns;
    is(scalar keys %dirty_after, 0, 'No dirty columns after discard');

    ok(!$row->is_column_changed('name'), 'Specific column is clean');
};

subtest 'set_column - with references and objects' => sub {
    plan tests => 3;

    my $row = $async_schema->resultset('User')->find($user->id)->get;

    # Set an arrayref
    my $arrayref = [1, 2, 3];
    $row->set_column('name', $arrayref);

    is($row->get_column('name'), $arrayref, 'Arrayref stored');
    ok($row->is_column_changed('name'), 'Reference change marks dirty');

    # Set a hashref
    my $hashref = { key => 'value' };
    $row->set_column('email', $hashref);

    is($row->get_column('email'), $hashref, 'Hashref stored');
};

subtest 'set_column - error: missing column name' => sub {
    plan tests => 1;

    my $row = $async_schema->resultset('User')->find($user->id)->get;

    eval {
        $row->set_column(undef, 'value');
    };
    like($@, qr/column name required/i, 'Dies without column name');
};

subtest 'set_columns - error: not a hashref' => sub {
    plan tests => 2;

    my $row = $async_schema->resultset('User')->find($user->id)->get;

    eval {
        $row->set_columns(['name', 'Bob']);
    };
    like($@, qr/hashref.*required/i, 'Dies with arrayref');

    eval {
        $row->set_columns('name');
    };
    like($@, qr/hashref.*required/i, 'Dies with scalar');
};

subtest 'set_column - numeric values' => sub {
    plan tests => 4;

    my $row = $async_schema->resultset('User')->find($user->id)->get;

    $row->set_column('active', 0);
    is($row->get_column('active'), 0, 'Can set to 0');
    ok($row->is_column_changed('active'), 'Setting to 0 marks dirty');

    $row->set_column('active', 1);
    is($row->get_column('active'), 1, 'Can set to 1');

    $row->set_column('active', 42);
    is($row->get_column('active'), 42, 'Can set to any number');
};

subtest 'set_column - empty string' => sub {
    plan tests => 3;

    my $row = $async_schema->resultset('User')->find($user->id)->get;

    $row->set_column('name', '');
    is($row->get_column('name'), '', 'Can set to empty string');
    ok($row->is_column_changed('name'), 'Empty string marks dirty');

    $row->set_column('name', '');
    # Setting empty to empty shouldn't mark as dirty again
    # (but it will stay dirty from first change)
    is($row->get_column('name'), '', 'Remains empty string');
};

subtest 'workflow - create, modify, update' => sub {
    plan tests => 5;

    # Create new user
    my $new_user = $async_schema->resultset('User')
        ->create({
            name   => 'Workflow',
            email  => 'workflow@example.com',
            active => 1,
        })->get;

    ok($new_user->id, 'User created with ID');

    # Modify
    my $changes = {
        name   => 'Modified',
        active => 0,
    };
    $new_user->set_columns($changes);

    ok($new_user->is_column_changed('name'), 'Name marked dirty');
    ok($new_user->is_column_changed('active'), 'Active marked dirty');

    # Update
    $new_user->update($changes)->get;

    # Verify
    my $fresh = $schema->resultset('User')->find($new_user->id);
    is($fresh->name, 'Modified', 'Changes persisted');
    is($fresh->active, 0, 'All changes persisted');
};

subtest 'set_column - does not affect in_storage' => sub {
    plan tests => 2;

    my $row = $async_schema->resultset('User')->find($user->id)->get;

    ok($row->in_storage, 'Row is in storage initially');

    $row->set_column('name', 'ChangedName');
    ok($row->in_storage, 'Row still in storage after set_column');
};

# Cleanup
END {
    unlink $dbfile if -e $dbfile;
}

done_testing();
