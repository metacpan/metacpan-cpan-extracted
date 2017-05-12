use strict;
use warnings;

use Test::More;

BEGIN {
    eval "use DBD::SQLite ();";
    plan skip_all => 'DBD::SQLite required to run this test' if $@;

    eval "use SQL::Translator ();";
    plan skip_all => 'SQL::Translator required to run this test' if $@;

    plan( tests => 11 );
}

use lib 't/lib';
use TestSchema;
use File::Temp;

# setup
my( undef, $db ) = File::Temp::tempfile();
my $schema = TestSchema->connect( "dbi:SQLite:dbname=${db}", undef, undef );
$schema->deploy;
$schema->populate( 'TestTable', [ [ 'id' ], ( map { [ $_ ] } 1..40 ) ] );

{
    my $rs = $schema->resultset( 'TestTable' )->search( {}, { rows => 10, page => 2 } );
    my $pager = $rs->pageset;

    isa_ok( $pager, 'Data::Pageset' );
    is( $pager->pages_per_set, 10, 'pages_per_set' );
    is( $pager->{ mode }, 'fixed', 'mode' );
    is( $pager->current_page, 2, 'current_page' );
    is( scalar @{ $pager->pages_in_set }, 4, 'pages_in_set' );
}

{
    my $rs = $schema->resultset( 'TestTable' )->search( {}, { rows => 10, page => 3, pages_per_set => 2, pageset_mode => 'slide' } );
    my $pager = $rs->pageset;

    isa_ok( $pager, 'Data::Pageset' );
    is( $pager->pages_per_set, 2, 'pages_per_set' );
    is( $pager->{ mode }, 'slide', 'mode' );
    is( $pager->current_page, 3, 'current_page' );
    is( scalar @{ $pager->pages_in_set }, 2, 'pages_in_set' );
    is_deeply( $pager->pages_in_set, [ 3, 4 ], 'pages_in_set' );
}

