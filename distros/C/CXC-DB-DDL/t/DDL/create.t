#! perl

use Test2::V0;
use Test2::Tools::QuickDB;

use CXC::DB::DDL;
use CXC::DB::DDL::Util -all;
use CXC::DB::DDL::Constants -all;

skipall_unless_can_db( DBD_SQLITE );

sub db {
    my $db  = get_db( { driver => DBD_SQLITE, nocache => 1 } );
    my $dbh = $db->connect;

    return ( $db, $dbh );
}

my %main = (
    name => 'main',
    xFIELDS(
        id => INTEGER(
            is_primary_key    => 1,
            is_auto_increment => 1,
        ),
    ),
);

my %dep = (
    name => 'dep',
    xFIELDS(
        id => INTEGER(
            foreign_key => {
                table     => 'main',
                on_delete => CASCADE,
            },
        ),
    ) );

subtest 'create once' => sub {

    my ( $db, $dbh ) = db;

    my $ddl = CXC::DB::DDL->new( \%main );

    ok( lives { $ddl->create( $dbh ) }, 'create' )
      or note $@;

    ok( $ddl->table( 'main' )->exists( $dbh ), 'table exists' );

    like( dies { $ddl->create( $dbh ) }, qr/attempt to create/, 'create again' )
      or note $@;
};

subtest 'create always' => sub {

    my ( $db, $dbh ) = db;

    subtest 'first creation' => sub {
        my $ddl = CXC::DB::DDL->new( \%main );

        $ddl->create( $dbh );

        ok( $ddl->table( 'main' )->exists( $dbh ), 'table exists' );

        # make sure there's something in there so we know
        # if it was dropped later on
        ok( lives { $dbh->do( 'insert into main default values' ) for 1 .. 3 }, 'insert rows' ) or note $@;

        is( $dbh->selectall_arrayref( 'select count(*) from main' )->[0][0], 3, 'got correct row count' );

    };

    subtest 'second creation' => sub {
        my $ddl = CXC::DB::DDL->new( \%main );

        $ddl->create( $dbh, create => CREATE_ALWAYS );
        ok( $ddl->table( 'main' )->exists( $dbh ), 'main table exists' );

        is( $dbh->selectall_arrayref( 'select count(*) from main' )->[0][0],
            0, 'got correct row count from main' );
    };
};

subtest 'create if not exists' => sub {

    my ( $db, $dbh ) = db;

    subtest 'create main' => sub {
        my $ddl = CXC::DB::DDL->new( \%main );

        $ddl->create( $dbh );

        ok( $ddl->table( 'main' )->exists( $dbh ), 'table exists' );

        # make sure there's something in there so we know
        # if it was dropped later on
        ok( lives { $dbh->do( 'insert into main default values' ) for 1 .. 3 }, 'insert rows' ) or note $@;

        is( $dbh->selectall_arrayref( 'select count(*) from main' )->[0][0], 3, 'got correct row count' );

    };

    subtest 'create dep' => sub {
        my $ddl = CXC::DB::DDL->new( [ \%main, \%dep ] );

        $ddl->create( $dbh, create => CREATE_IF_NOT_EXISTS );
        ok( $ddl->table( 'main' )->exists( $dbh ), 'main table exists' );
        ok( $ddl->table( 'dep' )->exists( $dbh ),  'dep table exists' );

        is( $dbh->selectall_arrayref( 'select count(*) from main' )->[0][0],
            3, 'got correct row count from main' );
    };
};

done_testing;
1;
