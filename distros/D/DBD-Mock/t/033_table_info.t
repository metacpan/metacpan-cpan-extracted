use 5.008;

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('DBI');
}

my $dbh = DBI->connect( 'dbi:Mock:', '', '' );
isa_ok($dbh, 'DBI::db');

my $columns  = [ 'TABLE_CAT', 'TABLE_SCHEM', 'TABLE_NAME', 'TABLE_TYPE', 'REMARKS' ];
my $fooTable = [ undef,       'testSchema',  'foo',        'TABLE',      undef     ];
my $barView  = [ undef,       'testSchema',  'bar',        'VIEW',       undef     ];
my $bazTable = [ undef,       'testSchema2', 'baz',        'TABLE',      'comment' ];

my $fooResult = {
    TABLE_CAT   => undef,
    TABLE_SCHEM => 'testSchema',
    TABLE_NAME  => 'foo',
    TABLE_TYPE  => 'TABLE',
    REMARKS     => undef,
};

my $barResult = {
    TABLE_CAT   => undef,
    TABLE_SCHEM => 'testSchema',
    TABLE_NAME  => 'bar',
    TABLE_TYPE  => 'VIEW',
    REMARKS     => undef,
};


my $sth = $dbh->table_info( undef, 'testSchema', 'foo', undef );

is_deeply( $sth->fetchall_arrayref( {} ), [], "No mocked table info should result an empty set of results being returned" );


$dbh->{mock_add_table_info} = {
    cataloge   => undef,
    schema     => 'testSchema',
    table      => 'foo',
    type       => undef,
    table_info => [ $columns, $fooTable ],
};

$dbh->{mock_add_table_info} = {
    cataloge   => undef,
    schema     => 'testSchema',
    table      => undef,
    type       => 'VIEW',
    table_info => [ $columns, $barView ],
};

$dbh->{mock_add_table_info} = {
    cataloge   => undef,
    schema     => 'testSchema',
    table      => undef,
    type       => undef,
    table_info => [ $columns, $fooTable, $barView ],
};


$sth = $dbh->table_info( undef, 'testSchema', undef, 'VIEW' );

is_deeply( $sth->fetchall_arrayref( {} ), [ $barResult ], "The matching mock results should be returned" );

$sth = $dbh->table_info( undef, 'testSchema', undef, undef );

is_deeply( $sth->fetchall_arrayref( {} ), [ $fooResult, $barResult ], "Search based up on the schema parameter only, should return in the set of results we've already defined" );


$dbh->{mock_clear_table_info} = 1;

$sth = $dbh->table_info( undef, 'testSchema', 'foo', undef );

is_deeply( $sth->fetchall_arrayref( {} ), [], "Clearing the mocked table info should result in no results being returned until mock_add_table_info is used to populate the table_info again" );

$dbh->{mock_add_table_info} = {
    schema     => '%',
    table_info => [
        [ 'TABLE_CAT', 'TABLE_SCHEM',  'TABLE_NAME', 'TABLE_TYPE', 'REMARKS' ],
        [ undef,       'testSchema',   undef,        undef,        undef     ],
        [ undef,       'testSchema_2', undef,        undef,        undef     ],
    ],
};

$sth = $dbh->table_info( undef, '%', undef, undef );

is_deeply( $sth->fetchall_arrayref( {} ), [
    {
        TABLE_CAT   => undef,
        TABLE_SCHEM => 'testSchema',
        TABLE_NAME  => undef,
        TABLE_TYPE  => undef,
        REMARKS     => undef,
    }, { 
        TABLE_CAT   => undef,
        TABLE_SCHEM => 'testSchema_2',
        TABLE_NAME  => undef,
        TABLE_TYPE  => undef,
        REMARKS     => undef,
    }
], "Mocking a search of schemas should return the records we've added" );



done_testing();
