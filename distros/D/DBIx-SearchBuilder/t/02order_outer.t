#!/usr/bin/perl -w


use strict;
use warnings;
use Test::More;
BEGIN { require "t/utils.pl" }
our (@AvailableDrivers);

use constant TESTS_PER_DRIVER => 98;

my $total = scalar(@AvailableDrivers) * TESTS_PER_DRIVER;
plan tests => $total;

foreach my $d ( @AvailableDrivers ) {
SKIP: {
	unless( has_schema( 'TestApp', $d ) ) {
		skip "No schema for '$d' driver", TESTS_PER_DRIVER;
	}
	unless( should_test( $d ) ) {
		skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
	}

	my $handle = get_handle( $d );
	connect_handle( $handle );
	isa_ok($handle->dbh, 'DBI::db');

	my $ret = init_schema( 'TestApp', $handle );
	isa_ok($ret,'DBI::st', "Inserted the schema. got a statement handle back");

    my $lowest = ($d ne 'Pg' && $d ne 'Oracle')? '-': 'z';

diag "generate data" if $ENV{TEST_VERBOSE};
{
    my @tags = qw(a b c d);
    foreach my $i ( 1..30 ) {
        my $number_of_tags = int(rand(4));
        my @t;
        push @t, $tags[int rand scalar @tags] while $number_of_tags--;
        my %seen = ();
        @t = grep !$seen{$_}++, @t;

        my $obj = TestApp::Object->new($handle);
        my ($oid) = $obj->Create( Name => join(",", sort @t) || $lowest );
        ok($oid,"Created record ". $oid);
        ok($obj->Load($oid), "Loaded the record");

        my $tags_ok = 1;
        foreach my $t( @t ) {
            my $tag = TestApp::Tag->new($handle);
            my ($tid) = $tag->Create( Object => $oid, Name => $t );
            $tags_ok = 0 unless $tid;
        }
        ok($tags_ok, "Added tags");
    }
}

# ASC order
foreach my $direction ( qw(ASC DESC) ) {
    my $objs = TestApp::Objects->new($handle);
    $objs->UnLimit;
    my $tags_alias = $objs->Join(
        TYPE   => 'LEFT',
        ALIAS1 => 'main',
        FIELD1 => 'id',
        TABLE2 => 'Tags',
        FIELD2 => 'Object',
    );
    ok($tags_alias, "joined tags table");
    $objs->OrderBy( ALIAS => $tags_alias, FIELD => 'Name', ORDER => $direction );

    ok($objs->First, 'ok, we have at least one result');
    $objs->GotoFirstItem;

    my ($order_ok, $last) = (1, $direction eq 'ASC'? '-': 'zzzz');
    while ( my $obj = $objs->Next ) {
        my $tmp;
        if ( $direction eq 'ASC' ) {
            $tmp = (substr($last, 0, 1) cmp substr($obj->Name, 0, 1));
        } else {
            $tmp = -(substr($last, -1, 1) cmp substr($obj->Name, -1, 1));
        }
        if ( $tmp > 0 ) {
            $order_ok = 0; last;
        }
        $last = $obj->Name;
    }
    ok($order_ok, "$direction order is correct") or do {
        diag "Wrong $direction query: ". $objs->BuildSelectQuery;
        $objs->GotoFirstItem;
        while ( my $obj = $objs->Next ) {
            diag($obj->id .":". $obj->Name);
        }
    }
}

	cleanup_schema( 'TestApp', $handle );
}} # SKIP, foreach blocks

1;

package TestApp;

sub schema_mysql { [
    "CREATE TEMPORARY TABLE Objects (
        id integer AUTO_INCREMENT,
        Name varchar(36),
      	PRIMARY KEY (id)
    )",
    "CREATE TEMPORARY TABLE Tags (
        id integer AUTO_INCREMENT,
        Object integer NOT NULL,
        Name varchar(36),
      	PRIMARY KEY (id)
    )",
] }

sub schema_pg { [
    "CREATE TEMPORARY TABLE Objects (
        id serial PRIMARY KEY,
        Name varchar(36)
    )",
    "CREATE TEMPORARY TABLE Tags (
        id serial PRIMARY KEY,
        Object integer NOT NULL,
        Name varchar(36)
    )",
]}

sub schema_sqlite {[
    "CREATE TABLE Objects (
        id integer primary key,
        Name varchar(36)
    )",
    "CREATE TABLE Tags (
        id integer primary key,
        Object integer NOT NULL,
        Name varchar(36)
    )",
]}

sub schema_oracle { [
    "CREATE SEQUENCE Objects_seq",
    "CREATE TABLE Objects (
        id integer CONSTRAINT Objects_Key PRIMARY KEY,
        Name varchar(36)
    )",
    "CREATE SEQUENCE Tags_seq",
    "CREATE TABLE Tags (
        id integer CONSTRAINT Tags_Key PRIMARY KEY,
        Object integer NOT NULL,
        Name varchar(36)
    )",
] }

sub cleanup_schema_oracle { [
    "DROP SEQUENCE Objects_seq",
    "DROP TABLE Objects", 
    "DROP SEQUENCE Tags_seq",
    "DROP TABLE Tags", 
] }


1;

package TestApp::Object;

use base $ENV{SB_TEST_CACHABLE}?
    qw/DBIx::SearchBuilder::Record::Cachable/:
    qw/DBIx::SearchBuilder::Record/;

sub _Init {
    my $self = shift;
    my $handle = shift;
    $self->Table('Objects');
    $self->_Handle($handle);
}

sub _ClassAccessible {
    {   
        id =>
        {read => 1, type => 'int(11)' }, 
        Name =>
        {read => 1, write => 1, type => 'varchar(36)' },
    }
}

1;

package TestApp::Objects;
use base qw/DBIx::SearchBuilder/;

sub _Init {
    my $self = shift;
    $self->SUPER::_Init( Handle => shift );
    $self->Table('Objects');
}

sub NewItem
{
	my $self = shift;
	return TestApp::Object->new( $self->_Handle );
}

1;

package TestApp::Tag;

use base $ENV{SB_TEST_CACHABLE}?
    qw/DBIx::SearchBuilder::Record::Cachable/:
    qw/DBIx::SearchBuilder::Record/;

sub _Init {
    my $self = shift;
    my $handle = shift;
    $self->Table('Tags');
    $self->_Handle($handle);
}

sub _ClassAccessible {
    {   
        id =>
        {read => 1, type => 'int(11)' },
        Object =>
        {read => 1, type => 'int(11)' },
        Name =>
        {read => 1, write => 1, type => 'varchar(36)' },
    }
}

1;

package TestApp::Tags;

# use TestApp::User;
use base qw/DBIx::SearchBuilder/;

sub _Init {
    my $self = shift;
    $self->SUPER::_Init( Handle => shift );
    $self->Table('Tags');
}

sub NewItem
{
	my $self = shift;
	return TestApp::Tag->new( $self->_Handle );
}

1;

