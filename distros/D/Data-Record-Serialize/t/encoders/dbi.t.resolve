#!perl

use Test2::V0;
use Test2::Tools::AfterSubtest;

use Test::Lib;

use Data::Record::Serialize;

use warnings;

eval 'use DBI; 1'
  or plan skip_all => "Need DBI to run the DBI backend tests\n";


our @DBDs;

eval 'use DBD::SQLite; 1'
  and push @DBDs, [ 'SQLite', '', '', '' ] ;


if ( $ENV{DBI_DRIVER} )
{
    diag( "unable to load DBD::$ENV{DBI_DRIVER}" )
      unless eval "use DBD::$ENV{DBI_DRIVER}; 1";

    push @DBDs, [ $ENV{DBI_DRIVER},
                  $ENV{DBI_DBNAME} || '',
                  $ENV{DBI_USER} || '',
                  $ENV{DBI_PASS} || ''
                  ],
}

@DBDs
  or plan skip_all =>
  "Need at least DBD::SQLite to run the DBI backend tests\n";

sub tmpfile {

    require File::Temp;

    # *BSD systems need EXLOCK=>0 to prevent lock contention (see docs
    # for File::Temp)
    return File::Temp->new( @_, EXLOCK => 0 );

}


my @test_data = (
    { a => 1, b => 2, c => 'nyuck nyuck' },
    { a => 3, b => 4, c => 'niagara falls' },
    { a => 5, b => 6, c => 'why youuu !' },
    { a => 7, b => 8, c => 'scale that fish !' },
    { a => 9, b => 10 },
);

my @expected_data = map { my $obj = { %$_ };
                          @{$obj}{ grep !defined $obj->{$_}, qw[ a b c ] } = undef;
                          $obj;
                      } @test_data;

# just in case we corrupt @test_data;
my $test_data_nrows = @test_data;

my $TEST_TABLE = "drststtbl";

my $after_cb = sub {};

after_subtest( sub { $after_cb->() } );


for my $dbinfo ( @DBDs ) {

    my $tmpfile;

    my ( $dbd, $db, $user, $pass ) = @$dbinfo;

    my $dbf;
    if ( $dbd eq 'SQLite' ) {
        $dbf = sub { $tmpfile = tmpfile(); $tmpfile->filename; };
    }
    else {

        $dbf = sub { $db } ;

        $after_cb = sub { clear_db( $dbd, $db, $user, $pass ) };

        $after_cb->();
    }


    subtest $dbd => sub {

        subtest 'autocommit' => sub {

            my $db = $dbf->();
            my $s;

            ok(
                lives {
                    $s = Data::Record::Serialize->new(
                        encode  => 'dbi',
                        dsn     => [ $dbd, { dbname => $db } ],
                        db_user => $user,
                        db_pass => $pass,
                        table   => $TEST_TABLE,
                        batch   => 1,
                    );
                },
                "constructor"
            ) or diag $@;

            $s->send( {%$_} ) foreach @test_data;
            $s->close;

            test_db( $dbd, $db, $user, $pass );

        };

        subtest 'transaction rows == batch' => sub {

            my $db = $dbf->();
            my $s;

            ok(
                lives {
                    $s = Data::Record::Serialize->new(
                        encode => 'dbi',
                        dsn    => [ $dbd, { dbname => $db } ],
                        table  => $TEST_TABLE,
                        batch  => $test_data_nrows,
                    );
                },
                "constructor"
            ) or diag $@;

            $s->send( {%$_} ) foreach @test_data;

            # dig beyond API to make sure that autocommit was really off _dbh
            # isn' t generated until the first send, so must do this check
            # after that.
            ok( !$s->_dbh->{AutoCommit},
                "Ensure that AutoCommit is really off" );

            $s->close;

            test_db( $dbd, $db, $user, $pass );
        };

        subtest 'transaction rows < batch' => sub {

            my $db = $dbf->();
            my $s;

            ok(
                lives {
                    $s = Data::Record::Serialize->new(
                        encode => 'dbi',
                        dsn    => [ $dbd, { dbname => $db } ],
                        table  => $TEST_TABLE,
                        batch  => $test_data_nrows + 1,
                    );
                },
                "constructor"
            ) or diag $@;

            $s->send( {%$_} ) foreach @test_data;
            $s->close;

            test_db( $dbd, $db, $user, $pass );
        };

        subtest 'transaction rows > batch' => sub {

            my $db = $dbf->();
            my $s;

            ok(
                lives {
                    $s = Data::Record::Serialize->new(
                        encode => 'dbi',
                        dsn    => [ $dbd, { dbname => $db } ],
                        table  => $TEST_TABLE,
                        batch  => $test_data_nrows - 1,
                    );
                },
                "constructor"
            ) or diag $@;

            $s->send( {%$_} ) foreach @test_data;

            $s->close;

            test_db( $dbd, $db, $user, $pass );
        };

        subtest 'drop table' => sub {

            my $db = $dbf->();
            my $s;

            my $dbh;
            ok(
                lives {
                    $dbh = DBI->connect( "dbi:${dbd}:dbname=${db}", $user, $pass, { RaiseError => 1 } );
                },
                'open db file'
            ) or diag $@;

            ok(
                lives {
                    $dbh->do( "create table $TEST_TABLE ( foo real )" );
                },
                'create table'
            ) or diag $@;
            $dbh->disconnect;

            ok(
                lives {
                    $s = Data::Record::Serialize->new(
                        encode     => 'dbi',
                        dsn        => [ $dbd, { dbname => $db } ],
                        table      => $TEST_TABLE,
                        batch      => $test_data_nrows - 1,
                        drop_table => 1,
                    );
                },
                "constructor"
            ) or diag $@;

            $s->send( {%$_} ) foreach @test_data;

            $s->close;

            test_db( $dbd, $db, $user, $pass );
        };

    };
}

sub test_db {

    my $ctx = context;

    my ( $dbd, $db, $user, $pass, $nrows ) = @_;

    $nrows ||= $test_data_nrows;

    my $dbh;
    my @rows;

    ok(
        lives {
            $dbh = DBI->connect( "dbi:${dbd}:dbname=${db}", $user, $pass,
                { RaiseError => 1 } );
        },
        'connect to db'
    ) or diag $@;

    my $sth;
    my $rows;
    ok(
        lives {
            $rows = $dbh->selectall_arrayref( "select * from $TEST_TABLE",
                { Slice => {} } );
        },
        'select rows from file',
    ) or diag $@;

    is( scalar @$rows, $test_data_nrows, 'correct number of rows' );

    is( $rows->[$_], $expected_data[$_], "row[$_]: stored data eq passed data" )
      foreach 0 .. $#expected_data;

    $ctx->release;
}

sub clear_db {

    my ( $dbd, $db, $user, $pass ) = @_;

    if ( $dbd ne 'SQLite' ) {
        my $dbh = DBI->connect( "dbi:${dbd}:dbname=${db}", $user, $pass,
                                { PrintError => 0 } )
          or bail_out( "Unable to connect to database: dbi:${dbd}:dbname=${db} user:$user" );
        $dbh->do( "drop table $TEST_TABLE cascade" );
    }
}

done_testing;
