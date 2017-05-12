use 5.006;

use strict;
use warnings;
use Test::Exception;
use Test::More tests => 6;

BEGIN {
    use_ok('DBD::Mock');
    use_ok('DBI');
}

my $dbh = DBI->connect( 'DBI:Mock:', '', '', { RaiseError => 1 } );
my $mock_session = DBD::Mock::Session->new(
    {
        statement    => qr/SELECT/,
        bound_params => [ 'US', '%joe%' ],
        results      => [
            [
                'person.person_id', 'person.person_country',
                'person.person_name'
            ],
            [ 1, 'AR', 'Joe Something' ],
            [ 2, 'UY', 'Joe That' ],
            [ 3, 'AR', 'Joe' ],
        ]
    }
);

$dbh->{mock_session} = $mock_session;

my $sth = $dbh->prepare("SELECT ...");
$sth->execute( 'US', '%joe%' );

my %row;

lives_ok(
    sub {
        $sth->bind_columns( \( @row{ @{ $sth->{NAME_lc} } } ) );
    },
    'Bind columns'
);

ok( exists $row{'person.person_name'},    'First column' );
ok( exists $row{'person.person_country'}, 'Second column' );
ok( exists $row{'person.person_id'},      'Third column' );
