use 5.008;

use strict;
use warnings;

use Test::More;

use DBD::Mock;
use DBD::Mock::dr;
use DBI;

my ( $dsn, $user, $password, $attributes );

DBD::Mock::dr::set_connect_callbacks( sub {
    ( my $dbh, $dsn, $user, $password, $attributes ) = @_;

    $dbh->{mock_add_resultset} = {
        sql => 'SELECT foo FROM bar',
        results => [[ 'foo' ], [ 10 ]]
    };        
} );

{
    my $dbh = DBI->connect('dbi:Mock:', '', '');
    isa_ok($dbh, 'DBI::db');

    my $sth = $dbh->prepare('SELECT foo FROM bar');
    isa_ok($sth, 'DBI::st');

    my $rows = $sth->execute();
    is($rows, '0E0', '... got back 0E0 for rows with a SELECT statement');

    my ($result) = $sth->fetchrow_array();

    is($result, 10, '... got the result we expected');

    $sth->finish();

}


# now let's check that we can reset the callbacks
DBD::Mock::dr::set_connect_callbacks( sub {
    ( my $dbh, $dsn, $user, $password, $attributes ) = @_;

    $dbh->{mock_add_resultset} = {
        sql => 'SELECT bar FROM foo',
        results => [[ 'bar' ], [ 50 ]]
    };
} );

{
    my $dbh = DBI->connect('dbi:Mock:', '', '');
    isa_ok($dbh, 'DBI::db');

    my $sth = $dbh->prepare('SELECT bar FROM foo');
    isa_ok($sth, 'DBI::st');

    my $rows = $sth->execute();
    is($rows, '0E0', '... got back 0E0 for rows with a SELECT statement');

    my ($result) = $sth->fetchrow_array();

    is($result, 50, '... got the result we expected');

    $sth->finish();

    $sth = $dbh->prepare('SELECT foo FROM bar');
    isa_ok($sth, 'DBI::st');

    $rows = $sth->execute();
    is($rows, '0E0', '... got back 0E0 for rows with a SELECT statement');

    ($result) = $sth->fetchrow_array();

    is($result, undef, "... as we have reset the callbacks this SELECT shouldn't match a result set ");

    $sth->finish();
}

# add_connect_callbacks adds a new callback to the list
DBD::Mock::dr::add_connect_callbacks( sub {
    ( my $dbh, $dsn, $user, $password, $attributes ) = @_;

    $dbh->{mock_add_resultset} = {
        sql => 'SELECT foo FROM bar',
        results => [[ 'foo' ], [ 10 ]]
    };        
} );

{
    my $dbh = DBI->connect('dbi:Mock:', '', '');
    isa_ok($dbh, 'DBI::db');

    my $sth = $dbh->prepare('SELECT bar FROM foo');
    isa_ok($sth, 'DBI::st');

    my $rows = $sth->execute();
    is($rows, '0E0', '... got back 0E0 for rows with a SELECT statement');

    my ($result) = $sth->fetchrow_array();

    is($result, 50, '... got the result we expected');

    $sth->finish();

    $sth = $dbh->prepare('SELECT foo FROM bar');
    isa_ok($sth, 'DBI::st');

    $rows = $sth->execute();
    is($rows, '0E0', '... got back 0E0 for rows with a SELECT statement');

    ($result) = $sth->fetchrow_array();

    is($result, 10, "... this should return a value as we've added its connect callback in");

    $sth->finish();
}

DBD::Mock::dr::set_connect_callbacks( sub {
    ( my $dbh, $dsn, $user, $password, $attributes ) = @_;

} );

{
    my $dbh = DBI->connect('dbi:Mock:database=TEST_DATABASE;hostname=localhost', 'TEST_USER', 'TEST_PASSWORD', { customAttribute => 1 });
    isa_ok($dbh, 'DBI::db');

    is ( $dsn, "database=TEST_DATABASE;hostname=localhost", "The database from the DSN should be passed through to the callback" );
    is ( $user, "TEST_USER", "The username should be passed through to the callback" );
    is ( $password, "TEST_PASSWORD", "The password should be passed through to the callback" );

    is ( ref $attributes, "HASH", "The attributes passed through to the callback should be a hash reference" );
    is ( $attributes->{customAttribute}, 1, "The custom attribute should be passed through to the callback" );
}

done_testing();
