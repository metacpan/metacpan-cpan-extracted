#! perl

use v5.26;
use Test2::V0;

use experimental 'signatures';

use CXC::DB::DDL;
use CXC::DB::DDL::Util -all;
use CXC::DB::DDL::Constants -all;



use Syntax::Keyword::Defer;

use File::Temp;
use File::Spec::Functions 'catfile';

use constant DRIVER => $ENV{CXC_DB_DDL_TEST_DBD} // DBD_SQLITE;

my $DBD = 'DBD::' . DRIVER;
eval "use $DBD; 1" // skip_all( "cannot find $DBD" );

sub db ( $dbd ) {

    if ( $dbd eq DBD_SQLITE ) {
        my $tmpdir = File::Temp->newdir( DIR => '/tmp' );    # make sure it's on a local disk
        my $db     = catfile( $tmpdir, 'test.db' );
        return bless {
            dbh    => DBI->connect( "dbi:$dbd:dbname=$db" ),
            tmpdir => $tmpdir
          },
          'Foo';
    }

    elsif ( $dbd eq DBD_POSTGRESQL ) {
        # rely on PG environment variables
        return bless { dbh => DBI->connect( "dbi:$dbd:", undef, undef ) }, 'Foo';
    }

    else {
        skip_all( "unsupported driver: $dbd" );
    }

}

my %main = (
    name => 'cxc_db_ddl_test_db_main',
    xFIELDS(
        id => INTEGER(
            is_primary_key    => 1,
            is_auto_increment => 1,
        ),
    ),
    constraints => [ {
            type   => UNIQUE,
            fields => '-all',
        },
        {
            type   => UNIQUE,
            fields => ['id'],
        },
    ],
);

my %dep = (
    name => 'cxc_db_ddl_test_db_dep',
    xFIELDS(
        id => INTEGER(
            foreign_key => {
                table     => $main{name},
                on_delete => CASCADE,
            },
        ),
    ) );

my %temporary = (
    name      => 'cxc_db_ddl_test_db_temporary',
    temporary => !!1,
    xFIELDS(
        id => INTEGER(),
    ) );

subtest 'create once' => sub {

    my $db  = db( DRIVER );
    my $dbh = $db->{dbh};

    my $ddl = CXC::DB::DDL->new( \%main );

    ok( lives { $ddl->create( $dbh ) }, 'create' )
      or bail_out $@;

    defer {
        ok( lives { $ddl->drop( $dbh ) }, "drop tables" )
    }

    ok( $ddl->table( $main{name} )->exists( $dbh ), 'table exists' );

    like( dies { $ddl->create( $dbh ) }, qr/attempt to create/, 'create again' )
      or bail_out $@;
};

subtest 'create always' => sub {

    my $db  = db( DRIVER );
    my $dbh = $db->{dbh};

    my $ddl;
    defer {
        $ddl->drop( $dbh );
    }

    subtest 'first creation' => sub {
        $ddl = CXC::DB::DDL->new( \%main );

        ok( lives { $ddl->create( $dbh ) }, 'create' )
          or bail_out $@;

        ok( $ddl->table( $main{name} )->exists( $dbh ), 'table exists' );

        # make sure there's something in there so we know
        # if it was dropped later on
        ok( lives { $dbh->do( "insert into $main{name} default values" ) for 1 .. 3 }, 'insert rows' )
          or bail_out $@;

        is( $dbh->selectall_arrayref( "select count(*) from $main{name}" )->[0][0],
            3, 'got correct row count' );

    };

    subtest 'second creation' => sub {
        $ddl = CXC::DB::DDL->new( \%main );

        ok( lives { $ddl->create( $dbh, create => CREATE_ALWAYS ) }, 'create' )
          or bail_out $@;

        ok( $ddl->table( $main{name} )->exists( $dbh ), 'main table exists' );

        is( $dbh->selectall_arrayref( "select count(*) from $main{name}" )->[0][0],
            0, 'got correct row count from $main{name}' );
    };
};

subtest 'create if not exists' => sub {

    my $db  = db( DRIVER );
    my $dbh = $db->{dbh};

    my $ddl;
    defer {
        $ddl->drop( $dbh );
    }

    subtest 'create main' => sub {
        $ddl = CXC::DB::DDL->new( \%main );

        ok( lives { $ddl->create( $dbh ) }, 'create' )
          or bail_out $@;

        ok( $ddl->table( $main{name} )->exists( $dbh ), 'table exists' );

        # make sure there's something in there so we know
        # if it was dropped later on
        ok( lives { $dbh->do( "insert into $main{name} default values" ) for 1 .. 3 }, 'insert rows' )
          or note $@;

        is( $dbh->selectall_arrayref( "select count(*) from $main{name}" )->[0][0],
            3, 'got correct row count' );

    };

    subtest 'create dep' => sub {
        $ddl = CXC::DB::DDL->new( [ \%main, \%dep ] );

        ok( lives { $ddl->create( $dbh, create => CREATE_IF_NOT_EXISTS ) }, 'create' )
          or bail_out $@;
        ok( $ddl->table( $main{name} )->exists( $dbh ), 'main table exists' );
        ok( $ddl->table( $dep{name} )->exists( $dbh ),  'dep table exists' );

        is( $dbh->selectall_arrayref( "select count(*) from $main{name}" )->[0][0],
            3, 'got correct row count from main' );
    };
};

subtest 'temporary table' => sub {

    my $db  = db( DRIVER );
    my $dbh = $db->{dbh};

    my $ddl = CXC::DB::DDL->new( \%temporary );
    ok( lives { $ddl->create( $dbh, create => CREATE_ONCE ) }, 'create' )
      or bail_out $@;

    my $sth = $dbh->table_info( undef, q{%}, $temporary{name}, 'LOCAL TEMPORARY' );
    my $row = $sth->fetchall_arrayref( {} );
    is( @$row, 1, 'table was created in temp schema' )
      or do { require Data::Dumper; diag Data::Dumper::Dumper( $row ) };
};

done_testing;
1;
