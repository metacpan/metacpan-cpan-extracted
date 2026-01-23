
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use DBIx::Class::Async;
use lib 't/lib';
use TestSchema;

{
    package TestSchema::Result::UserRole;
    use base 'DBIx::Class::Core';
    __PACKAGE__->table('user_roles');
    __PACKAGE__->add_columns(
        user_id => { data_type => 'integer' },
        role_id => { data_type => 'integer' },
    );

    __PACKAGE__->set_primary_key(qw/user_id role_id/);

    TestSchema->register_class('UserRole', 'TestSchema::Result::UserRole');
}

my ($fh, $filename) = tempfile(SUFFIX => '.db', UNLINK => 1);
close($fh);
my $dsn = "dbi:SQLite:dbname=$filename";

my $async = DBIx::Class::Async->new(
    schema_class => 'TestSchema',
    connect_info => [$dsn, '', ''],
    workers      => 1,
);

subtest 'Standard Insert Merge (User Table)' => sub {
    # 'User' has a single PK: 'id'
    my $original = { name => 'John Doe', email => 'john@example.com' };
    my $last_id  = 101; # Simulated return from SQLite last_insert_rowid()

    my $merged = $async->_merge_result_data('User', $original, $last_id);

    is($merged->{id}, 101, 'Auto-increment ID correctly assigned to "id" column');
    is($merged->{name}, 'John Doe', 'Original data preserved');
};

subtest 'Composite Key Hash Merge (Multi-column RETURNING)' => sub {
    # 'UserRole' has PK (user_id, role_id)
    my $original = { user_id => 5, role_id => 10 };

    # Simulated database return of the actual primary keys as a hashref
    # (Common in Postgres or drivers that return the affected row)
    my $db_result = { user_id => 5, role_id => 10, assigned_at => '2026-01-22' };

    my $merged = $async->_merge_result_data('UserRole', $original, $db_result);

    is($merged->{user_id}, 5, 'Composite user_id merged from hash');
    is($merged->{role_id}, 10, 'Composite role_id merged from hash');
    is($merged->{assigned_at}, '2026-01-22', 'Extra metadata from DB merged');
};

subtest 'Complex Hash Merge (Postgres/Defaults Style)' => sub {
    my $original = { name => 'Jane Doe' };
    # Simulated return where DB handles defaults (active = 1) and PK
    my $db_result = { id => 102, active => 1 };

    my $merged = $async->_merge_result_data('User', $original, $db_result);

    is($merged->{id}, 102, 'ID merged from hashref');
    is($merged->{active}, 1, 'Default value from DB correctly merged');
    is($merged->{name}, 'Jane Doe', 'Original data preserved');
};

subtest 'Composite Key Safety (Inline Package)' => sub {
    my $original = { user_id => 5, role_id => 10 };
    my $returned = 500; # The scalar ID that shouldn't be mapped

    my $merged = $async->_merge_result_data('UserRole', $original, $returned);

    is($merged->{user_id}, 5, 'Original user_id remains 5 (scalar ignored for composite PK)');
    is($merged->{role_id}, 10, 'Original role_id remains 10');
};

subtest 'Recursive Inflation (Prefetch)' => sub {
    my $complex_data = {
        id     => 1,
        name   => 'Bob',
        orders => [
            { id => 101, user_id => 1, amount => 50.00, status => 'pending' },
            { id => 102, user_id => 1, amount => 25.00, status => 'completed' },
        ],
    };

    # 1. Inflate using a copy to be safe
    my $user = $async->_inflate_row('User', { %$complex_data });

    # 2. Verifications
    isa_ok($user, 'DBIx::Class::Async::Row', 'Top level is a User object');
    is($user->{name}, 'Bob', 'User data is correct');

    # 3. Verification of nested data
    my $orders = $user->{orders};
    is(ref $orders, 'ARRAY', 'Orders is an array');
    is(scalar @$orders, 2, 'Found 2 orders');
    isa_ok($orders->[0], 'DBIx::Class::Async::Row', 'Nested Order 1 is inflated');
    isa_ok($orders->[1], 'DBIx::Class::Async::Row', 'Nested Order 2 is inflated');

    # 5. Check nested metadata
    is($orders->[0]->{source_name}, 'TestSchema::Result::Order', 'Order object knows its own source');
    is($orders->[0]->{amount}, 50.00, 'Nested data preserved in object');
};

subtest 'Recursive Inflation (The Bug Proof - Verified)' => sub {
    my $complex_data = {
        id     => 1,
        name   => 'Bob',
        orders => [ { id => 101, amount => 50 } ],
    };

    my $user = $async->_inflate_row('User', $complex_data);

    is($user->{name}, 'Bob', 'Top-level data found at object root');

    my $nested_order = $user->{orders}->[0];
    isa_ok($nested_order, 'DBIx::Class::Async::Row', 'Nested order object');
};

subtest 'Composite Key Array Merge (Positional)' => sub {
    # 'UserRole' has PK (user_id, role_id)
    my $original = { user_id => 0, role_id => 0 };
    my $db_array = [55, 99];

    my $merged = $async->_merge_result_data('UserRole', $original, $db_array);

    is($merged->{user_id}, 55, 'user_id mapped from array index 0');
    is($merged->{role_id}, 99, 'role_id mapped from array index 1');
};

done_testing();
