#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More;
BEGIN { require "t/utils.pl" }
our (@AvailableDrivers);

use constant TESTS_PER_DRIVER => 37;

my $total = scalar(@AvailableDrivers) * TESTS_PER_DRIVER;
plan tests => $total;

foreach my $d ( @AvailableDrivers ) {
SKIP: {
    unless( has_schema( 'TestApp::Address', $d ) ) {
        skip "No schema for '$d' driver", TESTS_PER_DRIVER;
    }
    unless( should_test( $d ) ) {
        skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
    }

    my $handle = get_handle( $d );
    connect_handle( $handle );
    isa_ok($handle->dbh, 'DBI::db');

    my $ret = init_schema( 'TestApp::Address', $handle );
    isa_ok($ret,'DBI::st', "Inserted the schema. got a statement handle back");

    {
        my $rec = TestApp::Address->new($handle);
        isa_ok($rec, 'DBIx::SearchBuilder::Record');
        my $id = $rec->Create;
        ok($id, 'created record');
        $rec->Load( $id );
        is($rec->id, $id, 'loaded record');
        is($rec->Optional, undef, 'correct value');
        is($rec->Mandatory, 1, 'correct value');
    }
    {
        my $rec = TestApp::Address->new($handle);
        isa_ok($rec, 'DBIx::SearchBuilder::Record');
        my $id = $rec->Create( Mandatory => undef );
        ok($id, 'created record');
        $rec->Load( $id );
        is($rec->id, $id, 'loaded record');
        is($rec->Optional, undef, 'correct value');
        is($rec->Mandatory, 1, 'correct value, we have default');
    }
    {
        my $rec = TestApp::Address->new($handle);
        isa_ok($rec, 'DBIx::SearchBuilder::Record');
        # Pg doesn't like "int_column = ''" syntax
        my $id = $rec->Create( Optional => '' );
        ok($id, 'created record');
        $rec->Load( $id );
        is($rec->id, $id, 'loaded record');
        is($rec->Optional, 0, 'correct value, fallback to 0 for empty string');
        is($rec->Mandatory, 1, 'correct value, we have default');

        # set operations on optional field
        my $status = $rec->SetOptional( 1 );
        ok($status, "status ok") or diag $status->error_message;
        is($rec->Optional, 1, 'set optional field to 1');

        $status = $rec->SetOptional( undef );
        ok($status, "status ok") or diag $status->error_message;
        is($rec->Optional, undef, 'undef equal to NULL');

        {
            my $warn;
            local $SIG{__WARN__} = sub {
                $warn++;
                warn @_;
            };
            $status = $rec->SetOptional('');
            ok( $status, "status ok" ) or diag $status->error_message;
            is( $rec->Optional, 0, 'empty string should be threated as zero' );
            ok( !$warn, 'no warning to set value from null to not-null' );
        }

        $status = $rec->SetOptional;
        ok($status, "status ok") or diag $status->error_message;
        is($rec->Optional, undef, 'no value is NULL too');

        $status = $rec->SetOptional;
        ok(!$status, 'same null value set');
        is(
            ( $status->as_array )[1],
            "That is already the current value",
            "correct error message"
        );
        is($rec->Optional, undef, 'no value is NULL too');

        # set operations on mandatory field
        $status = $rec->SetMandatory( 2 );
        ok($status, "status ok") or diag $status->error_message;
        is($rec->Mandatory, 2, 'set optional field to 2');

        $status = $rec->SetMandatory( undef );
        ok($status, "status ok") or diag $status->error_message;
        is($rec->Mandatory, 1, 'fallback to default');

        $status = $rec->SetMandatory( '' );
        ok($status, "status ok") or diag $status->error_message;
        is($rec->Mandatory, 0, 'empty string should be threated as zero');

        $status = $rec->SetMandatory;
        ok($status, "status ok") or diag $status->error_message;
        is($rec->Mandatory, 1, 'no value on set also fallback');
    }

    cleanup_schema( 'TestApp::Address', $handle );
}} # SKIP, foreach blocks

package TestApp::Address;

use base $ENV{SB_TEST_CACHABLE}?
    qw/DBIx::SearchBuilder::Record::Cachable/:
    qw/DBIx::SearchBuilder::Record/;

sub _Init {
    my $self = shift;
    my $handle = shift;
    $self->Table('MyTable');
    $self->_Handle($handle);
}

sub _ClassAccessible {
    {
        id =>
        { read => 1, type => 'int(11)' },
        Optional =>
        { read => 1, write => 1, type => 'int(11)' },
        Mandatory =>
        { read => 1, write => 1, type => 'int(11)', default => 1, no_nulls => 1 },
    }
}

sub schema_mysql {
<<EOF;
CREATE TEMPORARY TABLE MyTable (
        id integer PRIMARY KEY AUTO_INCREMENT,
        Optional integer NULL,
        Mandatory integer NOT NULL DEFAULT 1
)
EOF

}

sub schema_pg {
<<EOF;
CREATE TEMPORARY TABLE MyTable (
        id SERIAL PRIMARY KEY,
        Optional INTEGER NULL,
        Mandatory INTEGER NOT NULL DEFAULT 1
)
EOF

}

sub schema_sqlite {

<<EOF;
CREATE TABLE MyTable (
        id  integer primary key,
        Optional int(8) NULL,
        Mandatory integer NOT NULL DEFAULT 1
)
EOF

}

sub schema_oracle { [
    "CREATE SEQUENCE MyTable_seq",
    "CREATE TABLE MyTable (
        id integer CONSTRAINT MyTable_Key PRIMARY KEY,
        Optional INTEGER NULL,
        Mandatory integer DEFAULT 1 NOT NULL
    )",
] }

sub cleanup_schema_oracle { [
    "DROP SEQUENCE MyTable_seq",
    "DROP TABLE MyTable", 
] }


1;
