use strict;
use warnings;
use Test::More 0.98;
use DBI;
use lib 'lib';
use DBD::libsql;

# Test for issue #4: selectrow_hashref returns non-standard hash structure
# This test reproduces the bug where column names are hardcoded instead of
# being dynamically retrieved from the query result

# Mock data setup - simulate what libsql HTTP API would return
# The Hrana protocol returns: [{type: 'text', value: 'actual_value'}, ...]
my @mock_rows = (
    [
        {type => 'integer', value => 1},
        {type => 'text', value => 'テストユーザー'},
        {type => 'text', value => 'テストメッセージ'},
        {type => 'text', value => '2024-01-01T00:00:00Z'},
    ]
);

# Create a mock database handle for testing
my $dbh = bless {}, 'DBD::libsql::db';

# Create a mock statement handle with the result data
my $sth = bless {
    Statement => 'SELECT id, name, message, timestamp FROM posts WHERE id = 1',
    libsql_http_rows => \@mock_rows,
    libsql_fetch_index => 0,
}, 'DBD::libsql::st';

# Simulate what execute() does - extract column names from SQL
my @col_names = DBD::libsql::db::_extract_column_names($sth->{Statement});
$sth->{libsql_col_names} = \@col_names;

# Test 1: fetchrow_arrayref should extract values correctly
{
    my $row = $sth->fetchrow_arrayref();
    is_deeply $row, [1, 'テストユーザー', 'テストメッセージ', '2024-01-01T00:00:00Z'],
        'fetchrow_arrayref returns correct values from Hrana protocol format';
}

# Reset fetch index for next test
$sth->{libsql_fetch_index} = 0;

# Test 2: fetchrow_hashref should return hash with correct column names from SQL
{
    my $row = $sth->fetchrow_hashref();
    
    # These are the tests that SHOULD pass but currently fail (issue #4)
    is $row->{id}, 1, 'Column id should be 1';
    is $row->{name}, 'テストユーザー', 'Column name should be テストユーザー';
    is $row->{message}, 'テストメッセージ', 'Column message should be テストメッセージ (NOT value)';
    is $row->{timestamp}, '2024-01-01T00:00:00Z', 'Column timestamp should exist';
    
    # These should NOT exist or have different values in buggy version
    ok !exists $row->{value}, 'Column value should NOT exist (it overwrites message)';
    
    # Check that we have all expected columns
    my @expected_cols = qw(id name message timestamp);
    my @actual_cols = sort keys %$row;
    is_deeply \@actual_cols, [sort @expected_cols], 
        'Hash should have exactly the columns from the SELECT statement';
}

# Test 3: Different SQL query should return different column names
{
    $sth->{libsql_fetch_index} = 0;
    $sth->{Statement} = 'SELECT user_id, full_name, content, timestamp FROM comments WHERE id = 1';
    
    # Re-extract column names for new statement
    my @col_names = DBD::libsql::db::_extract_column_names($sth->{Statement});
    $sth->{libsql_col_names} = \@col_names;
    
    # Reuse same data but expect different column mapping
    my $row = $sth->fetchrow_hashref();
    
    # These should match the column names in the SQL statement
    is $row->{user_id}, 1, 'Column user_id should be 1';
    is $row->{full_name}, 'テストユーザー', 'Column full_name should be テストユーザー';
    is $row->{content}, 'テストメッセージ', 'Column content should be テストメッセージ';
    is $row->{timestamp}, '2024-01-01T00:00:00Z', 'Column timestamp should exist';
}

done_testing;

