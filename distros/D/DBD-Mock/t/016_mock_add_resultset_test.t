use strict;

use Test::More tests => 19;

BEGIN {
    use_ok('DBD::Mock');  
    use_ok('DBI');
}

# test the ability to overwrite a 
# hash based 'mock_add_resultset'
# and have it work as expected

# tests for the return value of execute below as well 

my $dbh = DBI->connect('dbi:Mock:', '', '');
isa_ok($dbh, 'DBI::db');

$dbh->{mock_add_resultset} = {
    sql => 'SELECT foo FROM bar',
    results => [[ 'foo' ], [ 10 ]]
};

{
    my $sth = $dbh->prepare('SELECT foo FROM bar');
    isa_ok($sth, 'DBI::st');

    my $rows = $sth->execute();
    is($rows, '0E0', '... got back 0E0 for rows with a SELECT statement');
    
    my ($result) = $sth->fetchrow_array();
    
    
    is($result, 10, '... got the result we expected');
    
    $sth->finish();
}

$dbh->{mock_add_resultset} = {
    sql => 'SELECT foo FROM bar',
    results => [[ 'foo' ], [ 50 ]]
};

{
    my $sth = $dbh->prepare('SELECT foo FROM bar');
    isa_ok($sth, 'DBI::st');

    my $rows = $sth->execute();
    is($rows, '0E0', '... got back 0E0 for rows with a SELECT statement');
    
    my ($result) = $sth->fetchrow_array();

    is($result, 50, '... got the result we expected');
    
    $sth->finish();
}

# get it again
{
    my $sth = $dbh->prepare('SELECT foo FROM bar');
    isa_ok($sth, 'DBI::st');

    my $rows = $sth->execute();
    is($rows, '0E0', '... got back 0E0 for rows with a SELECT statement');
    
    my ($result) = $sth->fetchrow_array();

    is($result, 50, '... got the result we expected');
    
    $sth->finish();
}

# and one more time for good measure
{
    my $sth = $dbh->prepare('SELECT foo FROM bar');
    isa_ok($sth, 'DBI::st');

    my $rows = $sth->execute();
    is($rows, '0E0', '... got back 0E0 for rows with a SELECT statement');

    my ($result) = $sth->fetchrow_array();

    is($result, 50, '... got the result we expected');
    
    $sth->finish();
}

## test the return value of execute

$dbh->{mock_add_resultset} = {
    sql => 'INSERT INTO foo VALUES(bar)',
    results => [[], []]
};

# check no SELECT statements
{
    my $sth = $dbh->prepare('INSERT INTO foo VALUES(bar)');
    isa_ok($sth, 'DBI::st');

    my $rows = $sth->execute();
    is($rows, 1, '... got back 1 for rows with our INSERT statement');

    $sth->finish();
}

$dbh->{mock_add_resultset} = {
    sql => 'UPDATE foo SET(bar = "baz")',
    results => [[], [], [], [], []]
};

# check no SELECT statements
{
    my $sth = $dbh->prepare('UPDATE foo SET(bar = "baz")');
    isa_ok($sth, 'DBI::st');

    my $rows = $sth->execute();
    is($rows, 4, '... got back 4 for rows with our UPDATE statement');

    $sth->finish();
}


