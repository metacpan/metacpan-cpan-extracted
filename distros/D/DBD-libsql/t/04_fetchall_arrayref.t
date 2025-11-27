use strict;
use warnings;
use Test::More 0.98;
use lib 'lib';
use DBD::libsql;

# Test for issue #19: $sth->fetchall_arrayref({}) returns empty array
# This test verifies that statement handle method fetchall_arrayref works correctly
# with different slice options (hash refs, array slices, default)

# Mock data setup - simulate what libsql HTTP API would return
my @mock_rows = (
    [
        {type => 'integer', value => 1},
        {type => 'text', value => 'User1'},
        {type => 'text', value => 'Message1'},
        {type => 'text', value => '2024-01-01T00:00:00Z'},
    ],
    [
        {type => 'integer', value => 2},
        {type => 'text', value => 'User2'},
        {type => 'text', value => 'Message2'},
        {type => 'text', value => '2024-01-02T00:00:00Z'},
    ]
);

# Create a mock statement handle with the result data
my $sth = bless {
    Statement => 'SELECT id, name, message, timestamp FROM test_posts ORDER BY id',
    libsql_http_rows => \@mock_rows,
    libsql_fetch_index => 0,
    Database => bless {}, 'DBD::libsql::db',
}, 'DBD::libsql::st';

# Manually set column names for this test
$sth->{libsql_col_names} = [qw(id name message timestamp)];

# Test 1: fetchall_arrayref with {} (hash slice) should return array of hashes
{
    my $rows = $sth->fetchall_arrayref({});
    
    ok(defined $rows, 'fetchall_arrayref({}) returns defined value');
    is(ref $rows, 'ARRAY', 'fetchall_arrayref({}) returns array reference');
    is(scalar(@$rows), 2, 'fetchall_arrayref({}) returns 2 rows (not empty array)');
    
    # Check first row
    is(ref $rows->[0], 'HASH', 'First row is hash reference');
    is($rows->[0]->{id}, 1, 'First row id is 1');
    is($rows->[0]->{name}, 'User1', 'First row name is User1');
    is($rows->[0]->{message}, 'Message1', 'First row message is Message1');
    is($rows->[0]->{timestamp}, '2024-01-01T00:00:00Z', 'First row timestamp is correct');
    
    # Check second row
    is(ref $rows->[1], 'HASH', 'Second row is hash reference');
    is($rows->[1]->{id}, 2, 'Second row id is 2');
    is($rows->[1]->{name}, 'User2', 'Second row name is User2');
    is($rows->[1]->{message}, 'Message2', 'Second row message is Message2');
    is($rows->[1]->{timestamp}, '2024-01-02T00:00:00Z', 'Second row timestamp is correct');
}

# Test 2: Reset and test fetchall_arrayref with default (no arguments)
{
    $sth->{libsql_fetch_index} = 0;
    my $rows = $sth->fetchall_arrayref();
    
    ok(defined $rows, 'fetchall_arrayref() returns defined value');
    is(ref $rows, 'ARRAY', 'fetchall_arrayref() returns array reference');
    is(scalar(@$rows), 2, 'fetchall_arrayref() returns 2 rows');
    
    # With default, should return array refs
    is(ref $rows->[0], 'ARRAY', 'First row is array reference (default behavior)');
    is($rows->[0]->[0], 1, 'First row first element is 1');
    is($rows->[0]->[1], 'User1', 'First row second element is User1');
}

# Test 3: fetchall_arrayref with max_rows parameter
{
    $sth->{libsql_fetch_index} = 0;
    my $rows = $sth->fetchall_arrayref({}, 1);
    
    ok(defined $rows, 'fetchall_arrayref({}, 1) returns defined value');
    is(scalar(@$rows), 1, 'fetchall_arrayref({}, 1) respects max_rows limit');
    is($rows->[0]->{id}, 1, 'Only first row returned when max_rows=1');
}

# Test 4: fetchall_arrayref with array slice
{
    $sth->{libsql_fetch_index} = 0;
    my $rows = $sth->fetchall_arrayref([0, 2]);  # Select id and message columns
    
    ok(defined $rows, 'fetchall_arrayref([0,2]) returns defined value');
    is(ref $rows, 'ARRAY', 'fetchall_arrayref([0,2]) returns array reference');
    is(scalar(@$rows), 2, 'fetchall_arrayref([0,2]) returns 2 rows');
    
    # With array slice, should return specific columns
    is(ref $rows->[0], 'ARRAY', 'First row is array reference with slice');
    is(scalar(@{$rows->[0]}), 2, 'First row has 2 elements (sliced)');
    is($rows->[0]->[0], 1, 'First row first element is id=1');
    is($rows->[0]->[1], 'Message1', 'First row second element is message');
}

# Test 5: Verify that fetchall_arrayref works after partial fetch
{
    $sth->{libsql_fetch_index} = 0;
    
    # Fetch one row manually
    my $first = $sth->fetchrow_hashref();
    is($first->{id}, 1, 'Manual fetch returns first row');
    
    # Now fetchall_arrayref should return remaining rows
    my $remaining = $sth->fetchall_arrayref({});
    is(scalar(@$remaining), 1, 'fetchall_arrayref returns remaining 1 row');
    is($remaining->[0]->{id}, 2, 'Remaining row is the second one');
}

# Test 6: Verify empty result set
{
    my $empty_sth = bless {
        Statement => 'SELECT id, name FROM test_posts WHERE id = 999',
        libsql_http_rows => [],
        libsql_fetch_index => 0,
        Database => bless {}, 'DBD::libsql::db',
    }, 'DBD::libsql::st';
    
    $empty_sth->{libsql_col_names} = [qw(id name)];
    
    my $rows = $empty_sth->fetchall_arrayref({});
    ok(defined $rows, 'fetchall_arrayref on empty result returns defined array');
    is(ref $rows, 'ARRAY', 'Empty result returns array reference');
    is(scalar(@$rows), 0, 'Empty result returns empty array (not undef)');
}

done_testing;
