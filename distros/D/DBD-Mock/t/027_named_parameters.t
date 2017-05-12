use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
    use_ok('DBD::Mock');
}

my $dbh = DBI->connect( 'DBI:Mock:', '', '' );

my $session = DBD::Mock::Session->new(
    (
        {
            statement    => 'SELECT * FROM foo WHERE id = ? and active = ?',
            bound_params => [ '613', 'yes' ],
            results      => [ ['foo'], [10] ]
        },
        {
            statement    => 'SELECT * FROM foo WHERE id = ? and active = ?',
            bound_params => [ '613', 'yes' ],
            results      => [ ['foo'], [10] ]
        },
        {
            statement =>
              'SELECT * FROM foo WHERE id = :id and active = :active',
            bound_params => [ '101', 'no' ],
            results => [ ['bar'], [15] ]
        },
        {
            statement =>
              'SELECT * FROM foo WHERE id = :id and active = :active',
            bound_params => [ '101', 'no' ],
            results => [ ['bar'], [15] ]
        },

    )
);

$dbh->{mock_session} = $session;

my $sth = $dbh->prepare('SELECT * FROM foo WHERE id = ? and active = ?');
$sth->bind_param( 1 => '613' );
$sth->bind_param( 2 => 'yes' );
ok( $sth->execute, 'Execute using positional parameters' );

$sth = $dbh->prepare('SELECT * FROM foo WHERE id = ? and active = ?');
ok( $sth->execute( '613', 'yes' ), 'Execute using positional parameters #2' );

$sth = $dbh->prepare('SELECT * FROM foo WHERE id = :id and active = :active');
$sth->bind_param( ':id'     => '101' );
$sth->bind_param( ':active' => 'no' );
ok( $sth->execute, 'Execute using named parameters' );

$sth = $dbh->prepare('SELECT * FROM foo WHERE id = :id and active = :active');
ok( $sth->execute( '101', 'no' ), 'Execute using named parameters #2' );
