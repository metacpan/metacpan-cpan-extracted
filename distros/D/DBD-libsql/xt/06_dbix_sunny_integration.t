use strict;
use warnings;
use Test::More 0.98;
use lib 'lib';
use DBD::libsql;

# Test DBIx::Sunny integration with DBD::libsql
# This tests that fetchrow_hashref and selectall_arrayref work correctly
# which are used by DBIx::Sunny's select_row and select_all methods

# Mock data setup - simulate what libsql HTTP API would return
my @mock_rows = (
    [
        {type => 'integer', value => 2},
        {type => 'text', value => 'User2'},
        {type => 'text', value => 'Message2'},
        {type => 'text', value => '2024-01-02T00:00:00Z'},
    ],
    [
        {type => 'integer', value => 1},
        {type => 'text', value => 'User1'},
        {type => 'text', value => 'Message1'},
        {type => 'text', value => '2024-01-01T00:00:00Z'},
    ]
);

# Create a mock statement handle with the result data
my $sth = bless {
    Statement => 'SELECT id, name, message, timestamp FROM posts ORDER BY id DESC',
    libsql_http_rows => \@mock_rows,
    libsql_fetch_index => 0,
    Database => bless {}, 'DBD::libsql::db',
}, 'DBD::libsql::st';

# Manually set column names for this test
$sth->{libsql_col_names} = [qw(id name message timestamp)];

# Test 1: fetchrow_hashref should work for single row retrieval (like DBIx::Sunny select_row)
{
    my $row = DBD::libsql::st::fetchrow_hashref($sth);
    
    ok defined $row, 'fetchrow_hashref returns a defined value (not undef)';
    is ref $row, 'HASH', 'Returns a hash reference';
    is $row->{id}, 2, 'Column id is correct';
    is $row->{name}, 'User2', 'Column name is correct';
    is $row->{message}, 'Message2', 'Column message is correct';
    is $row->{timestamp}, '2024-01-02T00:00:00Z', 'Column timestamp is correct';
}

# Test 2: Multiple fetchrow_hashref calls should return all rows
{
    my $row2 = DBD::libsql::st::fetchrow_hashref($sth);
    
    ok defined $row2, 'Second fetchrow_hashref returns a defined value';
    is $row2->{id}, 1, 'Second row id is correct';
    is $row2->{name}, 'User1', 'Second row name is correct';
}

# Test 3: fetchrow_hashref after exhausting rows should return undef
{
    my $row3 = DBD::libsql::st::fetchrow_hashref($sth);
    ok !defined $row3, 'fetchrow_hashref returns undef after all rows exhausted';
}

# Test 4: Verify that selectall_arrayref with Slice => {} works
# This simulates what DBIx::Sunny select_all uses internally
{
    my $dbh = bless {}, 'DBD::libsql::db';
    
    # Reset for new test
    $sth->{libsql_fetch_index} = 0;
    $sth->{Database} = $dbh;
    
    # Simulate selectall_arrayref with Slice => {}
    my @all_rows;
    my $attr = { Slice => {} };
    if ($attr && ref $attr eq 'HASH' && exists $attr->{Slice} && ref $attr->{Slice} eq 'HASH') {
        while (my $row = DBD::libsql::st::fetchrow_hashref($sth)) {
            push @all_rows, $row if defined $row;
        }
    }
    
    my $rows_ref = \@all_rows;
    
    ok defined $rows_ref, 'selectall_arrayref with Slice returns a defined value (not empty array)';
    ok ref $rows_ref eq 'ARRAY', 'Returns an array reference';
    is scalar @$rows_ref, 2, 'Returns correct number of rows';
    
    # Check first row
    is $rows_ref->[0]->{id}, 2, 'First row id is correct';
    is $rows_ref->[0]->{name}, 'User2', 'First row name is correct';
    is $rows_ref->[0]->{message}, 'Message2', 'First row message is correct';
    
    # Check second row
    is $rows_ref->[1]->{id}, 1, 'Second row id is correct';
    is $rows_ref->[1]->{name}, 'User1', 'Second row name is correct';
    is $rows_ref->[1]->{message}, 'Message1', 'Second row message is correct';
}

# Test 5: Verify that all fixes work together for complete DBIx::Sunny flow
{
    # Reset for final integration test
    $sth->{libsql_fetch_index} = 0;
    
    # Test like DBIx::Sunny select_row would (fetches single row as hash)
    my $single_row = DBD::libsql::st::fetchrow_hashref($sth);
    is_deeply $single_row,
        { id => 2, name => 'User2', message => 'Message2', timestamp => '2024-01-02T00:00:00Z' },
        'Single row fetch (DBIx::Sunny select_row) works correctly';
    
    # Reset and test like DBIx::Sunny select_all would (fetches all rows as hashes)
    $sth->{libsql_fetch_index} = 0;
    my @all_rows;
    while (my $row = DBD::libsql::st::fetchrow_hashref($sth)) {
        push @all_rows, $row if defined $row;
    }
    
    is scalar @all_rows, 2, 'select_all simulation fetches 2 rows';
    is $all_rows[0]->{id}, 2, 'First row in all_rows is correct';
    is $all_rows[1]->{id}, 1, 'Second row in all_rows is correct';
    ok scalar @all_rows > 0, 'select_all returns non-empty array (not [])';
}

done_testing;
