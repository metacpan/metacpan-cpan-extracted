use 5.006;

use strict;
use warnings;
use Test::Exception;
use Test::More tests => 7;

BEGIN {
    use_ok('DBD::Mock');
    use_ok('DBI');
}

my $dbh = DBI->connect( 'DBI:Mock:', '', '', { RaiseError => 1 } );
my $mock_session = DBD::Mock::Session->new(
    {
        statement => qr/SELECT name, id FROM person/,
        results   => [ [ 'name', 'id' ], [ 'Charles', 2 ], [ 'Wall', 3 ], ]
    },
    {
        statement => qr/SELECT email FROM client/,
        results   => [
            [ 'name',    'email' ],
            [ 'Charles', 'noreply@nodomain.com' ],
            [ 'Wall',    'noreply@nodomain.com' ],
        ]
    }
);

$dbh->{mock_session} = $mock_session;

my $first_sth;
my $second_sth;

lives_ok(
    sub {
        $second_sth = $dbh->prepare("SELECT email FROM client");
        $first_sth  = $dbh->prepare("SELECT name, id FROM person");

        $first_sth->execute();
        $second_sth->execute();

        my $row = $first_sth->fetchrow_hashref;
        is( $row->{name}, 'Charles', 'First statement first column' );
        is( $row->{id},   '2',       'First statement second column' );

        $row = $second_sth->fetchrow_hashref;
        is( $row->{name}, 'Charles', 'Second statement first column' );
        is( $row->{email}, 'noreply@nodomain.com',
            'Second statement second column' );

    },
    'Prepare two statements'
);

