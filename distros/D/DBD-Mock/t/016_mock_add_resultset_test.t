use 5.008;

use strict;
use warnings;

use Test::More;

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

## test regular expression for query matching
$dbh->{mock_add_resultset} = {
    sql => qr/^SELECT foo/,
    results => [ [ 'foo' ], [ 200 ] ],
};

## This one should never be used as the above one will have precedence
$dbh->{mock_add_resultset} = {
    sql => qr/^SELECT foo FROM/,
    results => [ [ 'foo' ], [ 300 ] ],
};

{
    my $sth = $dbh->prepare('SELECT foo FROM oof');
    isa_ok($sth, 'DBI::st');

    my $rows = $sth->execute();
    is($rows, '0E0', '... got back 0E0 for rows with a SELECT statement');

    my ($result) = $sth->fetchrow_array();

    is($result, 200, '... got the result we expected');

    $sth->finish();
}

## overwrite regular expression matching
$dbh->{mock_add_resultset} = {
    sql => qr/^SELECT foo/,
    results => [ [ 'foo' ], [ 400 ] ],
};

{
    my $sth = $dbh->prepare('SELECT foo FROM oof');
    isa_ok($sth, 'DBI::st');

    my $rows = $sth->execute();
    is($rows, '0E0', '... got back 0E0 for rows with a SELECT statement');

    my ($result) = $sth->fetchrow_array();

    is($result, 400, '... got the result we expected');

    $sth->finish();
}

# check that statically assigned queries take precedence over regex matched ones
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


$dbh->{mock_add_resultset} = {
    sql => 'SELECT x FROM y WHERE z = ?',
    results => [ ["x"] ],
    callback => sub {
        my @bound_params = @_;

        my %result = ( rows => [[ 1] ] );

        if ($bound_params[0] == 1) {
            $result{rows} = [ [32] ];
        } elsif ($bound_params[0] == 2) {
            $result{rows} = [ [43] ];
        }

        return %result;
    },
};

{
    my $sth = $dbh->prepare('SELECT x FROM y WHERE z = ?');
    isa_ok($sth, 'DBI::st');

    is($sth->{NUM_OF_FIELDS}, 1, "... When we specify the fields in the results parameter then we expect an answer from NUM_OF_FIELDS before we execute the statement");

    my $rows = $sth->execute(1);
    is($rows, '0E0', '... got back 0E0 for rows with a SELECT statement');

    is($sth->{NUM_OF_FIELDS}, 1, "... When we specify the fields in the results parameter then we expect an answer from NUM_OF_FIELDS after we execute the statement");

    my ($result) = $sth->fetchrow_array();

    is($result, 32, '... got the result we expected');

    $rows = $sth->execute(2);
    is($rows, '0E0', '... got back 0E0 for rows with a SELECT statement');

    ($result) = $sth->fetchrow_array();

    is($result, 43, '... got the result we expected');

    $rows = $sth->execute(33);
    is($rows, '0E0', '... got back 0E0 for rows with a SELECT statement');

    ($result) = $sth->fetchrow_array();

    is($result, 1, '... got the result we expected');
    $sth->finish();
}

$dbh->{mock_add_resultset} = {
    sql => 'SELECT a FROM b WHERE c = ?',
    callback => sub {
        my @bound_params = @_;

        my %result = (
            fields => [ "a" ],
            rows => [[ 1] ]
        );

        if ($bound_params[0] == 1) {
            $result{rows} = [ [32] ];
        } elsif ($bound_params[0] == 2) {
            $result{rows} = [ [43] ];
        }

        return %result;
    },
};

{
    my $sth = $dbh->prepare('SELECT a FROM b WHERE c = ?');
    isa_ok($sth, 'DBI::st');

    is($sth->{NUM_OF_FIELDS}, 0 , "... When we don't specify the fields in the results parameter and we haven't activated the DefaultFieldsToUndef feature, then we expect the NUM_OF_FIELDS to be 0 before we execute the statement");

    my $rows = $sth->execute(1);
    is($rows, '0E0', '... got back 0E0 for rows with a SELECT statement');

    is($sth->{NUM_OF_FIELDS}, 1, "... When we don't specify the fields in the results parameter then we still expect an answer from NUM_OF_FIELDS after we've execute the statement");

    my ($result) = $sth->fetchrow_array();

    is($result, 32, '... got the result we expected');

    $rows = $sth->execute(2);
    is($rows, '0E0', '... got back 0E0 for rows with a SELECT statement');

    ($result) = $sth->fetchrow_array();

    is($result, 43, '... got the result we expected');

    $rows = $sth->execute(33);
    is($rows, '0E0', '... got back 0E0 for rows with a SELECT statement');

    ($result) = $sth->fetchrow_array();

    is($result, 1, '... got the result we expected');
    $sth->finish();
}

{
    # Activate the DefaultFieldsToUndef feature
    $DBD::Mock::DefaultFieldsToUndef = 1;
    my $sth = $dbh->prepare('SELECT a FROM b WHERE c = ?');
    isa_ok($sth, 'DBI::st');

    is($sth->{NUM_OF_FIELDS}, undef , "... When we don't specify the fields in the results parameter then we expect the NUM_OF_FIELDS to be undef before we execute the statement");

    my $rows = $sth->execute(1);
    is($rows, '0E0', '... got back 0E0 for rows with a SELECT statement');

    is($sth->{NUM_OF_FIELDS}, 1, "... When we don't specify the fields in the results parameter then we still expect an answer from NUM_OF_FIELDS after we've execute the statement");

    my ($result) = $sth->fetchrow_array();

    is($result, 32, '... got the result we expected');

    $rows = $sth->execute(2);
    is($rows, '0E0', '... got back 0E0 for rows with a SELECT statement');

    ($result) = $sth->fetchrow_array();

    is($result, 43, '... got the result we expected');

    $rows = $sth->execute(33);
    is($rows, '0E0', '... got back 0E0 for rows with a SELECT statement');

    ($result) = $sth->fetchrow_array();

    is($result, 1, '... got the result we expected');
    $sth->finish();
}

$dbh->{mock_start_insert_id} = [ 'y', 4 ];

$dbh->{mock_add_resultset} = {
    sql => 'INSERT INTO y ( x ) VALUES ( ? )',
    callback => sub {
        my @bound_params = @_;

        my %result = (
            fields => [],
            rows => []
        );

        return %result;
    },
};

{
    my $sth = $dbh->prepare( 'INSERT INTO y ( x ) VALUES ( ? )' );

    $sth->execute( 'test' );

    is( $dbh->last_insert_id( (undef) x 4 ), 4, "last_insert_id should return the next Id value after an insert as our callback doesn't override it")
}


$dbh->{mock_add_resultset} = {
    sql => 'INSERT INTO y ( x ) VALUES ( ? )',
    callback => sub {
        my @bound_params = @_;

        my %result = (
            fields => [],
            rows => [],
            last_insert_id => 99,
        );

        return %result;
    },
};

{
    my $sth = $dbh->prepare( 'INSERT INTO y ( x ) VALUES ( ? )' );

    $sth->execute( 'test' );

    is( $dbh->last_insert_id( (undef) x 4 ), 99, "last_insert_id should return the id the callback has provided");

    is( $dbh->{mock_last_insert_ids}{y}, 5, "If we provide a last_insert_id value then the one stored against the table shouldn't be updated");
}


done_testing();
