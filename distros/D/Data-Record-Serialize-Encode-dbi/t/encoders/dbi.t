#!perl

# SQLite is tested against if it is available.  It is possible to
# add another DBD to test against in addition to SQLite
# by setting some environment variables.  To *only* test the alternate
# setup, set the environment variable
#
#  TEST_DRSE_ALTERNATE_ONLY
#
#  to a true value.

# Set just enough of the following variables to get the connection to
# work; no check is made to see if it is overspecified.

#  TEST_DRSE_DBNAME
#  TEST_DRSE_DRIVER => DBD driver name
#  TEST_DRSE_HOST
#  TEST_DRSE_PASSWORD
#  TEST_DRSE_PORT
#  TEST_DRSE_SCHEMA
#  TEST_DRSE_SERVER
#  TEST_DRSE_TABLE
#  TEST_DRSE_USER

use Test2::V0;
use Test2::Tools::AfterSubtest;

use User::pwent;
use Test::TempDir::Tiny;
use Data::Record::Serialize;
use List::Util 1.33 qw( any );
use Path::Tiny;

# for some reason during tests our new 'lib' dir does not have the
# highest priority when Data::Record::Serialize searches for encoders,
# and pre-installed versions of this module will get used.
use lib Path::Tiny->cwd->child('lib');

eval { require DBI; 1 }
  or plan skip_all => "Need DBI to run the DBI backend tests\n";

my @DBDs;

my $DBD_SQLite_VERSION = 1.31;

use constant TABLE     => 'drst_sttbl';
use constant SQLITE_DB => 'foo/bar/test.db';

my @dsn_fields = qw(
  dbname
  host
  password
  port
  schema
  server
  table
  user
);

eval { require DBD::SQLite; 1; }
  && push @DBDs,
  {
    dbname => SQLITE_DB,
    dbd    => 'SQLite',
    table  => TABLE,
  };

if ( defined( my $driver = $ENV{TEST_DRSE_DRIVER} ) ) {
    diag( "unable to load DBD::$driver" )
      unless eval "use DBD::$driver; 1";    ## no critic (BuiltinFunctions::ProhibitStringyEval)

    my %dbd = map {
        my $envvar = 'TEST_DRSE_' . uc( $_ );
        exists $ENV{$envvar} ? ( $_ => $ENV{$envvar} ) : ();
    } @dsn_fields;
    $dbd{dbd} = $driver;
    $dbd{table} //= TABLE;
    push @DBDs, \%dbd;

    $dbd{user} //= getpwuid( $< )->name;

    shift @DBDs if $ENV{TEST_DRSE_ALTERNATE_ONLY};
}

@DBDs
  or plan skip_all =>
  "Need at least DBD::SQLite (>= $DBD_SQLite_VERSION) to run the DBI backend tests\n";

my @test_data = (
    { a => 1,  b => 2, c => 'nyuck nyuck' },
    { a => 3,  b => 4, c => 'niagara falls' },
    { a => 5,  b => 6, c => 'why youuu !' },
    { a => 7,  b => 8, c => 'scale that fish !' },
    { a => 9,  c => q{that's all folks} },
    { a => 11, b => undef, c => q{pronoun problems} },
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

    my %dbinfo = %$dbinfo;
    my ( $dbd, $user, $password, $schema, $table )
      = delete @dbinfo{ 'dbd', 'user', 'password', 'schema', 'table' };
    $user     //= q{};
    $password //= q{};

    my $dsn              = mk_dsn( $dbd, %dbinfo );
    my %constructor_args = (
        encode            => 'dbi',
        create_table      => !!1,
        quote_identifiers => !!1,
        create_output_dir => !!1,
    );
    @constructor_args{ 'dsn', 'db_user', 'db_pass', 'schema', 'table' }
      = ( [ $dbd, \%dbinfo ], $user, $password, $schema, $table );

    my $dbf;
    if ( $dbd eq 'SQLite' ) {
        $dbf = sub { SQLITE_DB };
    }
    else {
        $dbf      = sub { $dbinfo{dbname} };
        clear_db( $dsn, $user, $password, $schema, $table );
        $after_cb = sub { clear_db( $dsn, $user, $password, $schema, $table ) };
        $after_cb->();
    }

    my @test_args = ( $dsn, $user, $password, $schema, $table );

    subtest $dbd => sub {

        subtest 'autocommit' => sub {
            in_tempdir $dbd => sub {
                my $s;

                ok(
                    lives {
                        $s = Data::Record::Serialize->new( %constructor_args, batch => 1, );
                    },
                    'constructor',
                ) or diag $@;

                $s->send( {%$_} ) foreach @test_data;
                $s->close;
                test_db( @test_args );
            };
        };

        subtest 'transaction rows == batch' => sub {
            in_tempdir $dbd => sub {
                my $s;

                ok(
                    lives {
                        $s = Data::Record::Serialize->new( %constructor_args, batch => $test_data_nrows, );
                    },
                    'constructor',
                ) or diag $@;

                $s->send( {%$_} ) foreach @test_data;

                # dig beyond API to make sure that autocommit was really off _dbh
                # isn' t generated until the first send, so must do this check
                # after that.
                ok( !$s->_dbh->{AutoCommit}, 'Ensure that AutoCommit is really off' );

                $s->close;

                test_db( @test_args );
            };
        };

        subtest 'transaction rows < batch' => sub {
            in_tempdir $dbd => sub {
                my $s;

                ok(
                    lives {
                        $s = Data::Record::Serialize->new( %constructor_args, batch => $test_data_nrows + 1, );
                    },
                    'constructor',
                ) or diag $@;

                $s->send( {%$_} ) foreach @test_data;
                $s->close;

                test_db( @test_args );
            };
        };

        subtest 'transaction rows > batch' => sub {
            in_tempdir $dbd => sub {
                my $s;

                ok(
                    lives {
                        $s = Data::Record::Serialize->new( %constructor_args, batch => $test_data_nrows - 1, );
                    },
                    'constructor',
                ) or diag $@;

                $s->send( {%$_} ) foreach @test_data;

                $s->close;

                test_db( @test_args );
            };
        };

        subtest 'drop table' => sub {
            in_tempdir $dbd => sub {

                my $dbh;
                ok(
                    lives {
                        $dbh = dbi_connect( $dsn, $user, $password, { RaiseError => 1 } );
                    },
                    'open db file',
                ) or diag $@;

                is( table_exists( $dbh, $schema, $table ), F(), "$table doesn't exist" );

                my $fq_table = $dbh->quote_identifier( undef, $schema, $table );

                ok(
                    lives {
                        $dbh->do( "create table $fq_table ( foo real )" );
                    },
                    'create table',
                ) or diag $@;
                $dbh->disconnect;

                my $s;
                ok(
                    lives {
                        $s = Data::Record::Serialize->new(
                            %constructor_args,
                            batch      => $test_data_nrows - 1,
                            drop_table => 1,
                        );
                    },
                    'constructor',
                ) or diag $@;

                $s->send( {%$_} ) foreach @test_data;
                $s->close;
                test_db( @test_args );
            };
        };
    };
}

sub test_db {
    my $ctx = context;
    my ( $dsn, $user, $password, $schema, $table ) = @_;

    my $dbh;

    ok(
        lives {
            $dbh = dbi_connect( $dsn, $user, $password, { RaiseError => 1 } );
        },
        'connect to db',
    ) or diag $@;

    $table = $dbh->quote_identifier( undef, $schema, $table );

    my $rows;
    ok(
        lives {
            $rows = $dbh->selectall_arrayref( "select * from $table", { Slice => {} } );
        },
        'select rows from file',
    ) or diag $@;

    is( scalar @$rows, $test_data_nrows, 'correct number of rows' );

    is( $rows->[$_], $expected_data[$_], "row[$_]: stored data eq passed data" )
      foreach 0 .. $#expected_data;

    ok(
        lives {
            $rows = $dbh->selectall_arrayref( "select * from $table where b is null", { Slice => {} } );
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
                field c => q{that's all folks};
                end;
            },
            hash {
                field a => 11;
                field b => undef;
                field c => 'pronoun problems';
                end;
            },
        ],
        'correct rows with nulls',
    );

    $ctx->release;
}

sub dbi_connect {
    my ( $dsn, $user, $password, $attr ) = @_;
    my %attr = %$attr;
    $attr{syb_quoted_identifier} = 1 if $dsn =~ /^dbi:Sybase/;
    path( SQLITE_DB )->parent->mkdir
      if $dsn =~ /^dbi:SQLite/;
    return DBI->connect( $dsn, $user, $password, \%attr );
}


sub clear_db {
    my ( $dsn, $user, $pass, $schema, $table ) = @_;

    return if $dsn =~ /^dbi:SQLite/;

    my $dbh = dbi_connect( $dsn, $user, $pass, { PrintError => 0 } )
      or bail_out( "Unable to connect to database: $dsn, user:$user" );
    my $qtable = $dbh->quote_identifier( undef, $schema, $table );
    $dbh->do( "drop table $qtable" ) if table_exists( $dbh, $schema, $table );
}

sub mk_dsn {
    my ( $dbd, %dbinfo ) = @_;

    my $dbinfo = join( q{;}, map { $_ . q{=} . $dbinfo{$_} } keys %dbinfo );
    my $dsn    = "dbi:$dbd";
    $dsn .= ":$dbinfo" if length $dbinfo;
    return $dsn;
}

sub table_exists {
    my ( $dbh, $schema, $table ) = @_;

    # DBD::Sybase doesn't filter, so need to search
    my $matches = $dbh->table_info( q{%}, $schema, $table, 'TABLE' )->fetchall_arrayref;
    return any { $_->[2] eq $table } @{$matches};
}


done_testing;
