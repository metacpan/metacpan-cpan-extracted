
use v5.20;
use warnings;
use File::Temp ();
use Cwd ();
use FindBin ();
use Test::More;
use Beam::Make;
use Log::Any::Adapter Stderr => log_level => $ENV{HARNESS_IS_VERBOSE} ? 'debug' : 'fatal';

BEGIN {
    eval { require DBD::SQLite; DBD::SQLite->VERSION( 1.56 ); 1 }
        or plan skip_all => 'DBD::SQLite >= 1.56 required for this test';
};

my $cwd = Cwd::getcwd;
my $home = File::Temp->newdir();
chdir $home;

# Place to look for container files
my $SHARE_DIR = $ENV{BEAM_PATH} = join '/', $FindBin::Bin, 'share';

my $make = Beam::Make->new(
    conf => {
        # Make the schema
        'db.sqlite3' => {
            '$class' => 'Beam::Make::DBI::Schema',
            dbh => {
                '$ref' => 'dbi.yml:sqlite',
            },
            schema => [
                {
                    table => 'fizz',
                    columns => [
                        { fizz_id => 'INTEGER PRIMARY KEY AUTOINCREMENT' },
                        { foo => 'VARCHAR(255)' },
                    ],
                },
                {
                    table => 'buzz',
                    columns => [
                        { buzz_id => 'INTEGER PRIMARY KEY AUTOINCREMENT' },
                        { name => 'VARCHAR(255) NOT NULL' },
                        { email => 'VARCHAR(255) NOT NULL' },
                    ],
                },
            ],
        },

        # Make an entire table
        foo => {
            '$class' => 'Beam::Make::DBI',
            requires => [qw( db.sqlite3 )],
            dbh => {
                '$ref' => 'dbi.yml:sqlite',
            },
            query => [
                q{INSERT INTO "fizz" ( foo ) VALUES ( 'row 1' )},
                q{INSERT INTO "fizz" ( foo ) VALUES ( 'row 2' )},
            ],
        },

        # Make a subset of rows in a table
        bar => {
            '$class' => 'Beam::Make::DBI',
            requires => [qw( foo )],
            dbh => {
                '$ref' => 'dbi.yml:sqlite',
            },
            query => [
                q{INSERT INTO "fizz" ( foo ) VALUES ( 'bar 1' )},
                q{INSERT INTO "fizz" ( foo ) VALUES ( 'bar 2' )},
            ],
        },

        # Load a CSV into a table
        baz => {
            '$class' => 'Beam::Make::DBI::CSV',
            requires => [qw( db.sqlite3 )],
            dbh => { '$ref' => 'dbi.yml:sqlite' },
            table => 'buzz',
            file => join( '/', $SHARE_DIR, 'dbi.csv' ),
        },
    },
);

subtest 'make a table' => sub {
    $make->run( 'foo' );
    ok -e 'db.sqlite3', 'db.sqlite3 is created';
    my $wire = Beam::Wire->new( file => join '/', $ENV{BEAM_PATH}, 'dbi.yml' );
    my $dbh = $wire->get( 'sqlite' );
    my $rows = $dbh->selectall_arrayref( 'SELECT * FROM "fizz"', { Slice => {} } );
    is scalar @$rows, 2, 'correct number of rows exist';
    is $rows->[0]{foo}, 'row 1', 'row 1 is correct';
    is $rows->[1]{foo}, 'row 2', 'row 2 is correct';
};

subtest 'add rows to the table' => sub {
    $make->run( 'bar' );
    ok -e 'db.sqlite3', 'db.sqlite3 still exists';
    my $wire = Beam::Wire->new( file => join '/', $ENV{BEAM_PATH}, 'dbi.yml' );
    my $dbh = $wire->get( 'sqlite' );
    my $rows = $dbh->selectall_arrayref( 'SELECT * FROM "fizz"', { Slice => {} } );
    is scalar @$rows, 4, 'correct number of rows exist';
    is $rows->[0]{foo}, 'row 1', 'row 1 is correct';
    is $rows->[1]{foo}, 'row 2', 'row 2 is correct';
    is $rows->[2]{foo}, 'bar 1', 'row 3 is correct';
    is $rows->[3]{foo}, 'bar 2', 'row 4 is correct';
};

subtest 'load a csv file' => sub {
    $make->run( 'baz' );
    ok -e 'db.sqlite3', 'db.sqlite3 still exists';
    my $wire = Beam::Wire->new( file => join '/', $ENV{BEAM_PATH}, 'dbi.yml' );
    my $dbh = $wire->get( 'sqlite' );
    my $rows = $dbh->selectall_arrayref( 'SELECT * FROM "buzz"', { Slice => {} } );
    is scalar @$rows, 2, 'correct number of rows exist';
    is $rows->[0]{name}, 'preaction', 'row 1 name is correct';
    is $rows->[0]{email}, 'preaction@example.com', 'row 1 email is correct';
    is $rows->[1]{name}, 'exodist', 'row 2 name is correct';
    is $rows->[1]{email}, 'exodist@example.com', 'row 2 email is correct';
};

chdir $cwd;
done_testing;
