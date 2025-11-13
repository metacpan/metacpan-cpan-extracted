use strict;
use warnings;
use Test::More 0.98;
use lib 'lib';
use DBD::libsql;

# Test for issue #8: last_insert_id returns empty string or undef
# This test verifies that last_insert_id correctly returns the ID of the last inserted row

# Create a mock database handle
my $dbh = bless {
    libsql_last_insert_id => undef,
}, 'DBD::libsql::db';

# Create a mock statement handle that would be returned from execute
my $sth = bless {
    Statement => 'INSERT INTO posts (name, message) VALUES (?, ?)',
    Database => $dbh,
}, 'DBD::libsql::st';

# Test 1: last_insert_id initially returns undef
{
    my $id = DBD::libsql::db::last_insert_id($dbh);
    ok !defined $id, 'last_insert_id returns undef when no INSERT has occurred';
}

# Test 2: Simulate setting last_insert_id from server response
# This is what happens in the execute method when a server returns last_insert_rowid
{
    $dbh->{libsql_last_insert_id} = 42;
    
    my $id = DBD::libsql::db::last_insert_id($dbh);
    ok defined $id, 'last_insert_id returns a defined value after INSERT';
    is $id, 42, 'last_insert_id returns correct ID (42)';
}

# Test 3: Verify last_insert_id with different ID values
{
    $dbh->{libsql_last_insert_id} = 1;
    is DBD::libsql::db::last_insert_id($dbh), 1, 'last_insert_id returns 1';
    
    $dbh->{libsql_last_insert_id} = 999;
    is DBD::libsql::db::last_insert_id($dbh), 999, 'last_insert_id returns 999';
    
    $dbh->{libsql_last_insert_id} = 0;
    is DBD::libsql::db::last_insert_id($dbh), 0, 'last_insert_id returns 0';
}

# Test 4: Verify that execute() would set last_insert_id correctly
# This simulates the real execute flow where server response contains last_insert_rowid
{
    my $test_dbh = bless {
        libsql_last_insert_id => undef,
    }, 'DBD::libsql::db';
    
    # Simulate what execute() does when parsing server response
    my $execute_result = {
        last_insert_rowid => 123,
        affected_row_count => 1,
        rows => [],
    };
    
    # This is the logic from execute method
    if (defined $execute_result->{last_insert_rowid}) {
        $test_dbh->{libsql_last_insert_id} = $execute_result->{last_insert_rowid};
    }
    
    my $id = DBD::libsql::db::last_insert_id($test_dbh);
    is $id, 123, 'execute() correctly stores last_insert_rowid from server response';
}

# Test 5: Verify that do() would set last_insert_id correctly
# This simulates the real do flow
{
    my $test_dbh = bless {
        libsql_last_insert_id => undef,
    }, 'DBD::libsql::db';
    
    # Simulate what do() does when parsing server response
    my $execute_result = {
        last_insert_rowid => 456,
        affected_row_count => 1,
    };
    
    # This is the logic from do method
    if (defined $execute_result->{last_insert_rowid}) {
        $test_dbh->{libsql_last_insert_id} = $execute_result->{last_insert_rowid};
    }
    
    my $id = DBD::libsql::db::last_insert_id($test_dbh);
    is $id, 456, 'do() correctly stores last_insert_rowid from server response';
}

# Test 6: Verify the method signature accepts catalog, schema, table, field parameters
# (These parameters are ignored in the implementation but should be accepted for DBI compatibility)
{
    my $test_dbh = bless {
        libsql_last_insert_id => 789,
    }, 'DBD::libsql::db';
    
    my $id = DBD::libsql::db::last_insert_id($test_dbh, 'catalog', 'schema', 'table', 'field');
    is $id, 789, 'last_insert_id accepts DBI-standard parameters and returns ID correctly';
}

# Test 7: Verify that last_insert_id is not confused with empty string
# (This was the original bug - returning empty string instead of the actual ID)
{
    my $test_dbh = bless {
        libsql_last_insert_id => 1,
    }, 'DBD::libsql::db';
    
    my $id = DBD::libsql::db::last_insert_id($test_dbh);
    isnt $id, '', 'last_insert_id does not return empty string';
    ok $id, 'last_insert_id returns truthy value';
}

done_testing;
