use strict;
use warnings;

use DBIx::FlexibleBinding -subs => ['TestDB'];
use Data::Dumper;
use Test::More;

$Data::Dumper::Terse  = 1;
$Data::Dumper::Indent = 1;

my @drivers = grep {/^SQLite$/} DBI->available_drivers();

SKIP: {
    skip( "iterate tests (No DBD::SQLite installed)", 1 ) unless @drivers;

    TestDB "dbi:SQLite:test.db", '', '', {};

    my $sth = TestDB->prepare( << '//');
   SELECT solarSystemID   AS id
        , solarSystemName AS name
        , security
     FROM mapsolarsystems
    WHERE solarSystemName REGEXP "^U[^0-9\-]+$"
 ORDER BY id, name, security DESC
    LIMIT 5
//

    my $it = $sth->iterate(
        callback {
            my ( $row ) = @_;
            $row->{filled_with} = ( $row->{security} >= 0.5 ) ? 'Carebears' : 'Yarrbears';
            $row->{security} = sprintf( '%.1f', $row->{security} );
            return $row;
        }
    );

    my @rows;
    while ( my $row = $it->() ) {
        push @rows, $row;
    }

    my $expected_result = [
        { 'name'        => 'Uplingur',
          'filled_with' => 'Yarrbears',
          'id'          => '30000037',
          'security'    => '0.4'
        },
        { 'security'    => '0.4',
          'id'          => '30000040',
          'name'        => 'Uzistoon',
          'filled_with' => 'Yarrbears'
        },
        { 'name'        => 'Usroh',
          'filled_with' => 'Carebears',
          'id'          => '30000068',
          'security'    => '0.6'
        },
        { 'filled_with' => 'Yarrbears',
          'name'        => 'Uhtafal',
          'id'          => '30000101',
          'security'    => '0.5'
        },
        { 'security'    => '0.3',
          'id'          => '30000114',
          'name'        => 'Ubtes',
          'filled_with' => 'Yarrbears'
        }
    ];

    is_deeply( \@rows, $expected_result, 'iterate' );
}

done_testing();
