# This is test for bug rt#82243 - Bug with Regex in DBD::Mock::Session
use 5.008;

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('DBD::Mock');
    use_ok('DBI');
}

{
    my $dbh = DBI->connect('dbi:Mock:', '', '', { RaiseError => 1, PrintError => 0 });
    isa_ok($dbh, 'DBI::db');
    
    my $session = DBD::Mock::Session->new((
        {
            statement    => 'SELECT bar FROM foo WHERE baz = ?',
            bound_params => [ qr/^125$/ ],
            results      => [[ 'bar' ], [ 15 ]]
        },
    ));
    isa_ok($session, 'DBD::Mock::Session');
    
    $dbh->{mock_session} = $session;
    
    my $sth = $dbh->prepare('SELECT bar FROM foo WHERE baz = ?');
    $sth->execute(125);
    my ($result) = $sth->fetchrow_array();
    is($result, 15, 'Regex matching on bound_params should work as expected.');

    # Shuts up warning when object is destroyed
    undef $dbh->{mock_session};
}

done_testing();
