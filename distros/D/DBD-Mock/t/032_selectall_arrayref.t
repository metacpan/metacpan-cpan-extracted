use 5.008;

use strict;
use warnings;

use Test::More;

use DBD::Mock;
use DBI;

my $dbh = DBI->connect( 'DBI:Mock:', '', '' );

{
    my $rows = [
        [ '1',  'european', '42' ],
        [ '27', 'african',  '2' ],
    ];

    $dbh->{mock_add_resultset} = {
        sql => 'SELECT id, type, inventory_id FROM Swallow',
        results => [
            [ 'id', 'type', 'inventory_id' ],
            @{ $rows },
        ]
    };

    my $results = $dbh->selectall_arrayref( 'SELECT id, type, inventory_id FROM Swallow' );

    is_deeply( $results, $rows, 'SELECTALL_ARRAYREF ref by default returns the rows from the result set' );


    my $expectedResults = [
        {
            id           => 1,
            type         => 'european',
            inventory_id => 42,

        }, {
            id           => 27,
            type         => 'african',
            inventory_id => 2,
        },
    ];

    $results = $dbh->selectall_arrayref( 'SELECT id, type, inventory_id FROM Swallow', { Slice => {} } );

    is_deeply( $results, $expectedResults, 'SELECTALL_ARRAYREF ref with a slice defined should return each row as a hashref' );

    
    $results = $dbh->selectall_arrayref( 'SELECT id, type, inventory_id FROM Swallow', { Slice => { 'id' => 1 } } );

    $expectedResults = [
        {
            id => 1,
        }, {
            id => 27,
        },
    ];

    is_deeply( $results, $expectedResults, 'SELECTALL_ARRAYREF ref with a slice defining column names should return each row as a hashref which only contains those columns' );


    $expectedResults = [
        [ 'european', 42 ],
        [ 'african',  2],
    ];

    $results = $dbh->selectall_arrayref( 'SELECT id, type, inventory_id FROM Swallow', { Columns => [2,3] } );

    is_deeply( $results, $expectedResults, 'SELECTALL_ARRAYREF ref with Columns defined should return just those columns' );
}

done_testing();
