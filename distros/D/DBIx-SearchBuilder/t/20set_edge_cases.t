#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More;
BEGIN { require "./t/utils.pl" }
our (@AvailableDrivers);

use constant TESTS_PER_DRIVER => 20;

my $total = scalar(@AvailableDrivers) * TESTS_PER_DRIVER;
plan tests => $total;

foreach my $d (@AvailableDrivers) {
  SKIP: {
        unless ( has_schema( 'TestApp::Address', $d ) ) {
            skip "No schema for '$d' driver", TESTS_PER_DRIVER;
        }
        unless ( should_test($d) ) {
            skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
        }

        my $handle = get_handle($d);
        connect_handle($handle);
        isa_ok( $handle->dbh, 'DBI::db' );

        my $ret = init_schema( 'TestApp::Address', $handle );
        isa_ok( $ret, 'DBI::st',
            "Inserted the schema. got a statement handle back" );

        my $rec = TestApp::Address->new($handle);
        my ($id) = $rec->Create( Name => 'foo', Counter => 3 );
        ok( $id,             "Created record " . $id );
        ok( $rec->Load($id), "Loaded the record" );

        is( $rec->Name,   'foo', "name is foo" );
        is( $rec->Counter, 3,     "number is 3" );

        my ( $val, $msg ) = $rec->SetName('bar');
        ok( $val, $msg );
        is( $rec->Name, 'bar', "name is changed to bar" );

        ( $val, $msg ) = $rec->SetName(undef);
        ok( !$val, $msg );
        like( $msg, qr/Illegal value for non-nullable field Name/, 'error message' );
        is( $rec->Name, 'bar', 'name is still bar' );

        SKIP: {
            skip 'Oracle treats the empty string as a NULL' => 2 if $d eq 'Oracle';
            ( $val, $msg ) = $rec->SetName('');
            ok( $val, $msg );
            is( $rec->Name, '', "name is changed to ''" );
        }

        ( $val, $msg ) = $rec->SetCounter(42);
        ok( $val, $msg );
        is( $rec->Counter, 42, 'number is changed to 42' );

        ( $val, $msg ) = $rec->SetCounter(undef);
        ok( !$val, $msg );
        like( $msg, qr/Illegal value for non-nullable field Counter/, 'error message' );
        is( $rec->Counter, 42, 'number is still 42' );

        ( $val, $msg ) = $rec->SetCounter('');
        ok( $val, $msg );
        is( $rec->Counter, 0, 'empty string implies 0 for integer field' );

        cleanup_schema( 'TestApp::Address', $handle );
    }
}

1;

package TestApp::Address;

use base $ENV{SB_TEST_CACHABLE}
  ? qw/DBIx::SearchBuilder::Record::Cachable/
  : qw/DBIx::SearchBuilder::Record/;

sub _Init {
    my $self   = shift;
    my $handle = shift;
    $self->Table('Address');
    $self->_Handle($handle);
}

sub _ClassAccessible {

    {
        id     => { read => 1, type  => 'int(11)', },
        Name   => { read => 1, write => 1, type => 'varchar(14)', no_nulls => 1 },
        Counter => { read => 1, write => 1, type => 'int(8)', no_nulls => 1 },
    };
}

sub schema_mysql {
    <<EOF;
CREATE TEMPORARY TABLE Address (
        id integer AUTO_INCREMENT,
        Name varchar(36) NOT NULL,
        Counter int(8) NOT NULL,
  	PRIMARY KEY (id))
EOF

}

sub schema_pg {
    <<EOF;
CREATE TEMPORARY TABLE Address (
        id serial PRIMARY KEY,
        Name varchar(36) NOT NULL,
        Counter integer NOT NULL
)
EOF

}

sub schema_sqlite {

    <<EOF;
CREATE TABLE Address (
        id  integer primary key,
        Name varchar(36) NOT NULL,
        Counter int(8) NOT NULL)
EOF

}

sub schema_oracle {
    [
        "CREATE SEQUENCE Address_seq",
        "CREATE TABLE Address (
        id integer CONSTRAINT Address_Key PRIMARY KEY,
        Name varchar(36) NOT NULL,
        Counter integer NOT NULL
        )",
    ];
}

sub cleanup_schema_oracle {
    [ "DROP SEQUENCE Address_seq", "DROP TABLE Address", ];
}

1;
