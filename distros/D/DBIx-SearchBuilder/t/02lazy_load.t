use strict;
use warnings;
use Test::More;

BEGIN { require "./t/utils.pl" }
our (@AvailableDrivers);

use constant TESTS_PER_DRIVER => 31 + ( $ENV{SB_TEST_CACHABLE} ? 2 : 0 );

my $total = scalar(@AvailableDrivers) * TESTS_PER_DRIVER;
plan tests => $total;

foreach my $d (@AvailableDrivers) {
SKIP: {
        diag("Running tests for $d");
        unless ( has_schema( 'TestApp::Person', $d ) ) {
            skip "No schema for '$d' driver", TESTS_PER_DRIVER;
        }
        unless ( should_test($d) ) {
            skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
        }

        my $handle = get_handle($d);
        connect_handle($handle);
        isa_ok( $handle->dbh, 'DBI::db' );

        # Each driver gets a clean cache so entries from a previous driver's
        # run (same in-process %_CACHES) don't bleed into this one.
        TestApp::Person->FlushCache if $ENV{SB_TEST_CACHABLE};

        my $ret = init_schema( 'TestApp::Person', $handle );
        isa_ok( $ret, 'DBI::st', "Inserted the schema. got a statement handle back" );

        my $rec = TestApp::Person->new($handle);
        my $id  = $rec->Create( Name => 'Alice', Bio => 'A long biography.' );
        ok( $id, "Created record $id" );

        # LoadByCols: eager column is pre-fetched, lazy column is not
        my $loaded = TestApp::Person->new($handle);
        $loaded->LoadByCols( Name => 'Alice' );
        is( $loaded->id, $id, "LoadByCols found the record" );

        ok( $loaded->{'fetched'}{'name'}, "Name (eager) is pre-fetched after LoadByCols" );
        ok( !$loaded->{'fetched'}{'bio'}, "Bio (lazy_load) is NOT pre-fetched after LoadByCols" );

        is( $loaded->Name, 'Alice',             "Name value is correct (from prefetch)" );
        is( $loaded->Bio,  'A long biography.', "Bio value is correct (fetched on demand)" );
        ok( $loaded->{'fetched'}{'bio'}, "Bio is now marked fetched after access" );

        # LoadById: same behaviour since it delegates to LoadByCols
        my $by_id = TestApp::Person->new($handle);
        $by_id->LoadById($id);
        is( $by_id->id, $id, "LoadById found the record" );

        ok( $by_id->{'fetched'}{'name'}, "Name (eager) is pre-fetched after LoadById" );
        if ( $ENV{SB_TEST_CACHABLE} ) {
            ok( $by_id->{'fetched'}{'bio'}, "Bio (lazy_load) is cached" );
            is( $by_id->Bio, 'A long biography.', "Bio value is correct" );
            TestApp::Person->FlushCache;
        }

        $by_id->LoadById($id);
        ok( !$by_id->{'fetched'}{'bio'}, "Bio (lazy_load) is NOT pre-fetched after LoadById" );
        is( $by_id->Bio, 'A long biography.', "Bio value is correct via LoadById" );

        # Collection: lazy_load columns not fetched by SELECT
        my $id2 = do {
            my $r = TestApp::Person->new($handle);
            $r->Create( Name => 'Bob', Bio => 'Another biography.' );
        };
        ok( $id2, "Created second record $id2" );

        my $coll = TestApp::Persons->new($handle);
        $coll->UnLimit;
        $coll->OrderBy( FIELD => 'id' );

        my $first = $coll->Next;
        ok( $first,                      "Got first record from collection" );
        ok( $first->{'fetched'}{'name'}, "Name (eager) is pre-fetched in collection" );
        ok( !$first->{'fetched'}{'bio'}, "Bio (lazy_load) is NOT pre-fetched in collection" );
        is( $first->Name, 'Alice',             "Name value correct from collection" );
        is( $first->Bio,  'A long biography.', "Bio value correct on demand from collection" );
        ok( $first->{'fetched'}{'bio'}, "Bio is now fetched after access in collection" );

        TestApp::Person->FlushCache if $ENV{SB_TEST_CACHABLE};

        # LoadByCols with SelectAllColumns: Bio should be pre-fetched
        my $all_cols = TestApp::Person->new($handle);
        $all_cols->SelectAllColumns(1);
        $all_cols->LoadByCols( Name => 'Alice' );
        is( $all_cols->id, $id, "SelectAllColumns: LoadByCols found the record" );
        ok( $all_cols->{'fetched'}{'name'}, "SelectAllColumns: Name is pre-fetched" );
        ok( $all_cols->{'fetched'}{'bio'},  "SelectAllColumns: Bio is pre-fetched after LoadByCols" );
        is( $all_cols->Bio, 'A long biography.', "SelectAllColumns: Bio value correct" );

        # LoadById with SelectAllColumns
        my $all_cols2 = TestApp::Person->new($handle);
        $all_cols2->SelectAllColumns(1);
        $all_cols2->LoadById($id);
        ok( $all_cols2->{'fetched'}{'bio'}, "SelectAllColumns: Bio is pre-fetched after LoadById" );
        is( $all_cols2->Bio, 'A long biography.', "SelectAllColumns: Bio value correct via LoadById" );

        # Collection with SelectAllColumns: Bio should be pre-fetched
        my $coll_all = TestApp::Persons->new($handle);
        $coll_all->SelectAllColumns(1);
        $coll_all->UnLimit;
        $coll_all->OrderBy( FIELD => 'id' );

        my $first_all = $coll_all->Next;
        ok( $first_all,                      "Got first record from collection with SelectAllColumns" );
        ok( $first_all->{'fetched'}{'name'}, "Name is pre-fetched with SelectAllColumns" );
        ok( $first_all->{'fetched'}{'bio'},  "Bio (lazy_load) is pre-fetched with SelectAllColumns" );
        is( $first_all->Name, 'Alice',             "Name value correct with SelectAllColumns" );
        is( $first_all->Bio,  'A long biography.', "Bio value correct with SelectAllColumns" );

        cleanup_schema( 'TestApp::Person', $handle );
    }
}    # SKIP, foreach blocks

1;

package TestApp::Persons;

use base qw/DBIx::SearchBuilder/;

sub _Init {
    my $self   = shift;
    my $handle = shift;
    $self->Table('Persons');
    $self->_Handle($handle);
}

sub NewItem { return TestApp::Person->new( (shift)->_Handle ) }

package TestApp::Person;

use base $ENV{SB_TEST_CACHABLE}
    ? qw/DBIx::SearchBuilder::Record::Cachable/
    : qw/DBIx::SearchBuilder::Record/;

sub _Init {
    my $self   = shift;
    my $handle = shift;
    $self->Table('Persons');
    $self->_Handle($handle);
}

sub _ClassAccessible {
    {   id   => { read => 1, type  => 'int(11)', default => '' },
        Name => { read => 1, write => 1,         type    => 'varchar(36)', default => '' },
        Bio  => { read => 1, write => 1,         type    => 'text', lazy_load => 1, default => '' },
    }
}

sub schema_sqlite {
    <<EOF;
CREATE TABLE Persons (
    id   integer primary key,
    Name varchar(36),
    Bio  text
)
EOF
}

sub schema_mysql {
    <<EOF;
CREATE TEMPORARY TABLE Persons (
    id   integer AUTO_INCREMENT,
    Name varchar(36),
    Bio  text,
    PRIMARY KEY (id)
) CHARACTER SET utf8mb4
EOF
}

sub schema_mariadb {
    <<EOF;
CREATE TEMPORARY TABLE Persons (
    id   integer AUTO_INCREMENT,
    Name varchar(36),
    Bio  text,
    PRIMARY KEY (id)
) CHARACTER SET utf8mb4
EOF
}

sub schema_pg {
    <<EOF;
CREATE TEMPORARY TABLE Persons (
    id   serial PRIMARY KEY,
    Name varchar,
    Bio  text
)
EOF
}

sub schema_oracle {
    [   "CREATE SEQUENCE Persons_seq",
        "CREATE TABLE Persons (
        id   integer CONSTRAINT Persons_Key PRIMARY KEY,
        Name varchar(36),
        Bio  CLOB
    )",
    ]
}

sub cleanup_schema_oracle {
    [ "DROP SEQUENCE Persons_seq", "DROP TABLE Persons", ]
}

1;
