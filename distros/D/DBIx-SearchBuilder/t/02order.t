#!/usr/bin/perl -w


use strict;
use warnings;
use Test::More;
BEGIN { require "./t/utils.pl" }
our (@AvailableDrivers);

use constant TESTS_PER_DRIVER => 379;

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

my @fields = (
    'Name',
    $d eq 'Oracle' ? 'TO_CHAR(Name)' : ($d eq 'mysql' || $d eq 'MariaDB') ? 'BINARY(Name)' : 'CAST(Name AS TEXT)'
);

diag "test ordering objects by fields on Tags table" if $ENV{TEST_VERBOSE};
foreach my $direction ( qw(ASC DESC) ) {
foreach my $field (@fields ) {
foreach my $combine_search_and_count ( 0, 1 ) {
foreach my $per_page (0, 5) {
foreach my $page (0, 2) {
    my $objs = TestApp::Objects->new($handle);
    $objs->CombineSearchAndCount($combine_search_and_count);
    $objs->UnLimit;
    my $tags_alias = $objs->Join(
        TYPE   => 'LEFT',
        ALIAS1 => 'main',
        FIELD1 => 'id',
        TABLE2 => 'Tags',
        FIELD2 => 'Object',
    );
    ok($tags_alias, "joined tags table");
    # Generated SQL is MIN(Name) or nested functions like MIN(CAST(Name AS TEXT))
    $objs->OrderBy( ALIAS => $tags_alias, FIELD => $field, ORDER => $direction );
    $objs->RowsPerPage($per_page) if $per_page;
    $objs->GotoPage($page) if $page;

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
    };

    my $got_count = $objs->CountAll;
    is ($got_count, 30, "CountAll is expected");

}}}}} # foreach variants blocks

my $expected_count = 0;

diag "test ordering objects by object's fields with limit by tags" if $ENV{TEST_VERBOSE};
foreach my $direction ( qw(ASC DESC) ) {
foreach my $field ('Name', 'id') {
foreach my $combine_search_and_count ( 0, 1 ) {
foreach my $per_page (0, 5, 30) {
foreach my $page (0, 2) {
    my $objs = TestApp::Objects->new($handle);
    $objs->CombineSearchAndCount($combine_search_and_count);
    my $tags_alias = $objs->Join(
        ALIAS1 => 'main',
        FIELD1 => 'id',
        TABLE2 => 'Tags',
        FIELD2 => 'Object',
    );
    ok($tags_alias, "joined tags table");
    $objs->OrderBy( FIELD => $field, ORDER => $direction );
    $objs->RowsPerPage($per_page) if $per_page;
    $objs->GotoPage($page) if $page;

    $objs->Limit( ALIAS => $tags_alias, FIELD => 'Name', OPERATOR => 'IN', VALUE => ['c', 'a'] );

    my @list;
    while ( my $obj = $objs->Next ) {
        push @list, $field eq 'Name'? $obj->Name : $obj->Id;
    }
    my @correct = sort {$field eq 'Name'? $a cmp $b : $a <=> $b } @list;
    @correct = reverse @correct if $direction eq 'DESC';
    is_deeply(\@list, \@correct, "correct order");

    my $got_count = $objs->CountAll;
    if ($expected_count) {
        is($got_count, $expected_count, "count is correct");
    } else {
        $expected_count = $got_count;
    }
}}}}} # foreach variants blocks

diag "test ordering by expressions and with selected columns on joined searches" if $ENV{TEST_VERBOSE};
{
    # The LEFT JOIN to Tags may duplicate objects, so these searches are DISTINCT
    my $new_objs = sub {
        my $class = shift || 'TestApp::Objects';
        my $objs  = $class->new($handle);
        $objs->UnLimit;
        my $tags_alias = $objs->Join(
            TYPE   => 'LEFT',
            ALIAS1 => 'main',
            FIELD1 => 'id',
            TABLE2 => 'Tags',
            FIELD2 => 'Object',
        );
        return wantarray ? ( $objs, $tags_alias ) : $objs;
    };
    my $ids_of = sub {
        [ map { $_->id } @{ $_[0]->ItemsArrayRef || [] } ]
    };

    my $objs  = $new_objs->();
    my @first = grep { $_ % 3 == 0 } 1 .. 30;
    $objs->OrderByCols(
        {   ALIAS => '',
            FIELD => 'CASE WHEN main.id IN (' . join( ',', @first ) . ') THEN 0 ELSE 1 END',
            ORDER => 'ASC',
        },
        { FIELD => 'id', ORDER => 'ASC' },
    );
    is_deeply( $ids_of->($objs), [ @first, grep { $_ % 3 } 1 .. 30 ], 'ordered by an expression without an alias' );

SKIP: {
        skip "Oracle has no boolean expressions in ORDER BY", 1 if $d eq 'Oracle';
        $objs = $new_objs->();
        $objs->OrderByCols( { FIELD => 'id > 15', ORDER => 'ASC' }, { FIELD => 'id', ORDER => 'DESC' }, );
        is_deeply(
            $ids_of->($objs),
            [ reverse( 1 .. 15 ), reverse( 16 .. 30 ) ],
            'ordered by a boolean expression on main'
        );
    }

    my $expected = TestApp::Objects->new($handle);
    $expected->UnLimit;
    $expected->OrderByCols( { FIELD => 'Name', ORDER => 'DESC' }, { FIELD => 'id', ORDER => 'ASC' } );

    $objs = $new_objs->();
    $objs->Columns('id');
    $objs->OrderByCols( { FIELD => 'Name', ORDER => 'DESC' }, { FIELD => 'id', ORDER => 'ASC' } );
    is_deeply( $ids_of->($objs), $ids_of->($expected), 'ordered by a column outside the selected columns' );

    {
        # Lazy loading leaves Name out of the select list
        local $DBIx::SearchBuilder::PREFER_LAZY_LOAD = 1;
        $objs = $new_objs->('TestApp::LazyObjects');
        $objs->OrderByCols( { FIELD => 'Name', ORDER => 'DESC' }, { FIELD => 'id', ORDER => 'ASC' } );
        is_deeply( $ids_of->($objs), $ids_of->($expected), 'ordered by a lazy loaded column' );
    }

SKIP: {
        skip "No CombineSearchAndCount support", 2 unless $handle->HasSupportForCombineSearchAndCount;

        # The count query wraps SELECT DISTINCT, which hides columns outside the select list
        $objs = $new_objs->();
        $objs->Columns('id');
        $objs->CombineSearchAndCount(1);
        $objs->OrderByCols( { FIELD => 'Name', ORDER => 'DESC' }, { FIELD => 'id', ORDER => 'ASC' } );
        is_deeply( $ids_of->($objs), $ids_of->($expected),
            'ordered by a column outside the selected columns with CombineSearchAndCount' );
        is( $objs->Count, 30, 'counted with CombineSearchAndCount' );
    }

    # Compare each joined search with the same order on an unjoined search
    my $ordered_ids = sub {
        my $objs = TestApp::Objects->new($handle);
        $objs->UnLimit;
        $objs->OrderByCols(@_);
        return $ids_of->($objs);
    };

    my @order = ( { FIELD => 'LOWER(Name)', ORDER => 'DESC' }, { FIELD => 'id', ORDER => 'ASC' } );
    $objs = $new_objs->();
    $objs->OrderByCols(@order);
    is_deeply( $ids_of->($objs), $ordered_ids->(@order), 'ordered by a function of a column' );

    $objs = $new_objs->();
    $objs->Columns('id');
    $objs->OrderByCols(@order);
    is_deeply(
        $ids_of->($objs),
        $ordered_ids->(@order),
        'ordered by a function of a column outside the selected columns'
    );

    @order = (
        {   ALIAS => '',
            FIELD => "CASE WHEN main.Name LIKE '%a%' THEN 0 ELSE 1 END",
            ORDER => 'ASC',
        },
        { FIELD => 'id', ORDER => 'ASC' },
    );
    $objs = $new_objs->();
    $objs->Columns('id');
    $objs->OrderByCols(@order);
    is_deeply(
        $ids_of->($objs),
        $ordered_ids->(@order),
        'ordered by an expression on a column outside the selected columns'
    );

    @order = ( { ALIAS => 'main', FIELD => 'name', ORDER => 'DESC' }, { FIELD => 'id', ORDER => 'ASC' } );
    $objs  = $new_objs->();
    $objs->Columns('id');
    $objs->OrderByCols(@order);
    is_deeply(
        $ids_of->($objs),
        $ordered_ids->(@order),
        'ordered by a lower case column name outside the selected columns'
    );

    # An order row without an alias may name a selected function by its AS name
    @order = ( { ALIAS => '', FIELD => 'lname', ORDER => 'DESC' }, { FIELD => 'id', ORDER => 'ASC' } );
    my @lname_order = ( { FIELD => 'LOWER(Name)', ORDER => 'DESC' }, { FIELD => 'id', ORDER => 'ASC' } );
    $objs = $new_objs->();
    $objs->AdditionalColumn( FIELD => 'Name', FUNCTION => 'LOWER(?)', AS => 'lname' );
    $objs->OrderByCols(@order);
    is_deeply(
        $ids_of->($objs),
        $ordered_ids->(@lname_order),
        'ordered by the name of an additional selected function'
    );

    $objs = $new_objs->();
    $objs->Column( FIELD => 'id' );
    $objs->Column( FIELD => 'Name', FUNCTION => 'LOWER(?)', AS => 'lname' );
    $objs->OrderByCols(@order);
    is_deeply( $ids_of->($objs), $ordered_ids->(@lname_order), 'ordered by the name of a selected function' );

SKIP: {
        skip "No CombineSearchAndCount support", 1 unless $handle->HasSupportForCombineSearchAndCount;

        $objs = $new_objs->();
        $objs->AdditionalColumn( FIELD => 'Name', FUNCTION => 'LOWER(?)', AS => 'lname' );
        $objs->CombineSearchAndCount(1);
        $objs->OrderByCols(@order);
        is_deeply(
            $ids_of->($objs),
            $ordered_ids->(@lname_order),
            'ordered by the name of a selected function with CombineSearchAndCount'
        );
    }

    # DISTINCT keeps one row per object and tag, and an untagged object once
    my %tag_count;
    my $tags = TestApp::Tags->new($handle);
    $tags->UnLimit;
    $tag_count{ $_->Object }++ for @{ $tags->ItemsArrayRef || [] };
    my @rows_per_tag = map { ($_) x ( $tag_count{$_} || 1 ) } 1 .. 30;

SKIP: {
        # Oracle's DistinctQuery selects from a DISTINCT main.id subquery,
        # which leaves joined tables out of the outer select
        skip "Oracle DISTINCT searches can't select columns of joined tables", 2 if $d eq 'Oracle';

        ( $objs, my $tags_alias ) = $new_objs->();
        $objs->Column( FIELD => 'id' );
        $objs->Column( ALIAS => $tags_alias, FIELD => 'Name' );
        $objs->OrderByCols( { FIELD => 'id', ORDER => 'ASC' } );
        is_deeply( $ids_of->($objs), \@rows_per_tag, 'ordered with a selected column of a joined table' );

        ( $objs, $tags_alias ) = $new_objs->();
        $objs->Column( FIELD => 'id' );
        $objs->Column( FIELD => 'Name', FUNCTION => 'LOWER(?)', AS => 'lname' );
        $objs->Column( ALIAS => $tags_alias, FIELD => 'Name' );
        $objs->OrderByCols(@lname_order);
        is_deeply(
            $ids_of->($objs),
            [ map { ($_) x ( $tag_count{$_} || 1 ) } @{ $ordered_ids->(@lname_order) } ],
            'ordered by a selected expression with a selected column of a joined table'
        );
    }

SKIP: {
        # Neither SELECT DISTINCT nor GROUP BY main.id can do this in Pg, MySQL 8 or Oracle
        skip "$d can't order by a column outside the selected columns of a joined table", 1
            unless $d eq 'SQLite' || $d eq 'MariaDB';

        ( $objs, my $tags_alias ) = $new_objs->();
        $objs->Column( FIELD => 'id' );
        $objs->Column( ALIAS => $tags_alias, FIELD => 'Name' );
        $objs->OrderByCols( { FIELD => 'Name', ORDER => 'ASC' } );
        is( scalar @{ $ids_of->($objs) },
            scalar @rows_per_tag,
            'kept rows of a selected column of a joined table when ordered by another column'
          );
    }
}

	cleanup_schema( 'TestApp', $handle );
}} # SKIP, foreach driver block

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
    "CREATE INDEX Tags1 ON Tags (Name)"
] }

sub schema_mariadb { [
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
    "CREATE INDEX Tags1 ON Tags (Name)"
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
    "CREATE INDEX Tags1 ON Tags (Name)"
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
    "CREATE INDEX Tags1 ON Tags (Name)"
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
    "CREATE INDEX Tags1 ON Tags (Name)"
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

package TestApp::LazyObject;
use base qw/TestApp::Object/;

sub _ClassAccessible {
    {   id   => { read => 1, type  => 'int(11)' },
        Name => { read => 1, write => 1, type => 'varchar(36)', lazy_load => 1 },
    }
}

1;

package TestApp::LazyObjects;
use base qw/TestApp::Objects/;

sub NewItem {
    my $self = shift;
    return TestApp::LazyObject->new( $self->_Handle );
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

