#!perl

use Test2::V0;
use Test2::Tools::AfterSubtest;

use Test::Lib;
use Test::TempDir::Tiny;
use Data::Record::Serialize;

eval { require DBI; 1 }
  or plan skip_all => "Need DBI to run the DBI backend tests\n";

our @DBDs;

my $DBD_SQLite_VERSION = 1.31;

use constant SQLITE_DB => 'test.db';

eval { require DBD::SQLite; DBD::SQLite->VERSION( $DBD_SQLite_VERSION ); 1; }
  && push @DBDs,
  {
    db      => SQLITE_DB,
    db_pass => '',
    db_user => '',
    dbd     => 'SQLite',
    schema  => undef,
    table   => 'drststtbl',
  };

if ( $ENV{DBI_DRIVER} ) {
    diag( "unable to load DBD::$ENV{DBI_DRIVER}" )
      unless eval "use DBD::$ENV{DBI_DRIVER}; 1";

    push @DBDs,
      {
        db      => $ENV{DBI_DBNAME} || '',
        db_pass => $ENV{DBI_PASS}   || '',
        db_user => $ENV{DBI_USER}   || '',
        dbd     => $ENV{DBI_DRIVER},
        schema  => $ENV{DBI_SCHEMA} || undef,
        table   => $ENV{DBI_TABLE}  || 'drststtbl',
      };
}

@DBDs
  or plan skip_all =>
  "Need at least DBD::SQLite (>= $DBD_SQLite_VERSION) to run the DBI backend tests\n";

my @test_data = (
    { a => 1, b => 2, c => 'nyuck nyuck' },
    { a => 3, b => 4, c => 'niagara falls' },
    { a => 5, b => 6, c => 'why youuu !' },
    { a => 7, b => 8, c => 'scale that fish !' },
    { a => 9, c => "that's all folks" },
    { a => 11, b => undef, c => "pronoun problems" },
);

my @expected_data = map {
    my $obj = {%$_};
    @{$obj}{ grep !defined $obj->{$_} || !length $obj->{$_}, qw[ a b c ] }
      = undef;
    $obj;
} @test_data;

# just in case we corrupt @test_data;
my $test_data_nrows = @test_data;

my $after_cb = sub { };

after_subtest( sub { $after_cb->() } );

for my $dbinfo ( @DBDs ) {
    my $tmpfile;

    my %dbinfo = %$dbinfo;
    my ( $db, $dbd ) = delete @dbinfo{ 'db', 'dbd' };
    $dbinfo{dsn} = [ $dbd, { dbname => $db } ];

    my $dbf;
    if ( $dbd eq 'SQLite' ) {
        $dbf = sub { SQLITE_DB };
    }
    else {
        $dbf      = sub { $db };
        $after_cb = sub { clear_db( $dbd, $db, %dbinfo ) };
        $after_cb->();
    }

    subtest $dbd => sub {
        $DB::single=1;

        subtest 'autocommit' => sub {
            in_tempdir $dbd => sub {
                my $db = $dbf->();
                my $s;

                ok(
                    lives {
                        $s = Data::Record::Serialize->new(
                            encode => 'dbi',
                            %dbinfo,
                            batch => 1,
                        );
                    },
                    "constructor"
                ) or diag $@;

                $s->send( {%$_} ) foreach @test_data;
                $s->close;
                test_db( $dbd, $db, %dbinfo );
            };
        };

        subtest 'transaction rows == batch' => sub {
            in_tempdir $dbd => sub {
                my $db = $dbf->();
                my $s;

                ok(
                    lives {
                        $s = Data::Record::Serialize->new(
                            encode => 'dbi',
                            %dbinfo,
                            batch => $test_data_nrows,
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

                test_db( $dbd, $db, %dbinfo );
            };
        };

        subtest 'transaction rows < batch' => sub {
            in_tempdir $dbd => sub {
                my $db = $dbf->();
                my $s;

                ok(
                    lives {
                        $s = Data::Record::Serialize->new(
                            encode => 'dbi',
                            %dbinfo,
                            batch => $test_data_nrows + 1,
                        );
                    },
                    "constructor"
                ) or diag $@;

                $s->send( {%$_} ) foreach @test_data;
                $s->close;

                test_db( $dbd, $db, %dbinfo );
            };
        };

        subtest 'transaction rows > batch' => sub {
            in_tempdir $dbd => sub {
                my $db = $dbf->();
                my $s;

                ok(
                    lives {
                        $s = Data::Record::Serialize->new(
                            encode => 'dbi',
                            %dbinfo,
                            batch => $test_data_nrows - 1,
                        );
                    },
                    "constructor"
                ) or diag $@;

                $s->send( {%$_} ) foreach @test_data;

                $s->close;

                test_db( $dbd, $db, %dbinfo );
            };
        };

        subtest 'drop table' => sub {
            in_tempdir $dbd => sub {
                my $db = $dbf->();
                my $s;

                my $dbh;
                ok(
                    lives {
                        $dbh = DBI->connect(
                            "dbi:${dbd}:dbname=${db}", $dbinfo{db_user},
                            $dbinfo{db_pass}, { RaiseError => 1 } );
                    },
                    'open db file'
                ) or diag $@;

                my $table = $dbh->quote_identifier( undef, $dbinfo{schema},
                    $dbinfo{table} );

                ok(
                    lives {
                        $dbh->do( "create table $table ( foo real )" );
                    },
                    'create table'
                ) or diag $@;
                $dbh->disconnect;

                ok(
                    lives {
                        $s = Data::Record::Serialize->new(
                            encode => 'dbi',
                            %dbinfo,
                            batch      => $test_data_nrows - 1,
                            drop_table => 1,
                        );
                    },
                    "constructor"
                ) or diag $@;

                $s->send( {%$_} ) foreach @test_data;
                $s->close;
                test_db( $dbd, $db, %dbinfo );
            };
        };
    };
}

sub test_db {
    my $ctx = context;
    my ( $dbd, $db, %dbinfo ) = @_;

    my $nrows = delete $dbinfo{nrows} // $test_data_nrows;

    my $dbh;
    my @rows;

    ok(
        lives {
            $dbh = DBI->connect(
                "dbi:${dbd}:dbname=${db}", $dbinfo{db_user},
                $dbinfo{db_pass}, { RaiseError => 1 } );
        },
        'connect to db'
    ) or diag $@;

    my $table
      = $dbh->quote_identifier( undef, $dbinfo{schema}, $dbinfo{table} );

    $DB::single = 1;
    my $sth;
    my $rows;
    ok(
        lives {
            $rows = $dbh->selectall_arrayref( "select * from $table",
                { Slice => {} } );
        },
        'select rows from file',
    ) or diag $@;

    is( scalar @$rows, $test_data_nrows, 'correct number of rows' );

    is( $rows->[$_], $expected_data[$_], "row[$_]: stored data eq passed data" )
      foreach 0 .. $#expected_data;

    ok(
        lives {
            $rows
              = $dbh->selectall_arrayref(
                "select * from $table where b is null",
                { Slice => {} } );
        },
        'select rows with b is NULL from file',
    ) or diag $@;

    # yeah, this is hard coded.
    is(
        $rows,
        [
            hash {
                field a => 9;
                field b => undef;
                field c => "that's all folks";
                end;
            },
            hash {
                field a => 11;
                field b => undef;
                field c => "pronoun problems";
                end;
            }
        ],
        "correct rows with nulls",
    );

    $ctx->release;
}

sub clear_db {
    my ( $dbd, $db, %dbinfo ) = @_;

    if ( $dbd ne 'SQLite' ) {
        my $dbh = DBI->connect(
            "dbi:${dbd}:dbname=${db}", $dbinfo{db_user},
            $dbinfo{db_pass}, { PrintError => 0 } )
          or bail_out(
            "Unable to connect to database: dbi:${dbd}:dbname=${db} user:$dbinfo{db_user}"
          );
        my $table
          = $dbh->quote_identifier( undef, $dbinfo{schema}, $dbinfo{table} );
        $dbh->do( "drop table $table cascade" );
    }
}

done_testing;
