#!/usr/bin/perl -w

use strict;
use Test::More;

BEGIN { require "t/utils.pl" }
our (@AvailableDrivers);

use constant TESTS_PER_DRIVER => 14;

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
    isa_ok($ret, 'DBI::st', "Inserted the schema. got a statement handle back");

    init_data( $_, $handle ) foreach qw(
        TestApp::User
        TestApp::Group
        TestApp::UsersToGroup
    );

diag "insert into table from other tables only" if $ENV{'TEST_VERBOSE'};
{
    my $res = $handle->InsertFromSelect(
        'UsersToGroups' => ['UserId', 'GroupId'],
        'SELECT id, 1 FROM Users WHERE Login LIKE ?', '%o%'
    );
    is( $res, 2 );
    my $users = TestApp::Users->new( $handle );
    my $alias = $users->Join( FIELD1 => 'id', TABLE2 => 'UsersToGroups', FIELD2 => 'UserId' );
    $users->Limit( ALIAS => $alias, FIELD => 'GroupId', VALUE => 1 );
    is_deeply( [ sort map $_->Login, @{ $users->ItemsArrayRef } ], ['bob', 'john'] );
}

diag "insert into table from two tables" if $ENV{'TEST_VERBOSE'};
{
    my $res = $handle->InsertFromSelect(
        'UsersToGroups' => ['UserId', 'GroupId'],
        'SELECT u.id as col1, g.id as col2 FROM Users u, Groups g WHERE u.Login LIKE ? AND g.Name = ?',
        '%a%', 'Support'
    );
    is( $res, 2 );
    my $users = TestApp::Users->new( $handle );
    my $u2g_alias = $users->Join( FIELD1 => 'id', TABLE2 => 'UsersToGroups', FIELD2 => 'UserId' );
    my $g_alias = $users->Join(
        ALIAS1 => $u2g_alias, FIELD1 => 'GroupId', TABLE2 => 'Groups', FIELD2 => 'id',
    );
    $users->Limit( ALIAS => $g_alias, FIELD => 'Name', VALUE => 'Support' );
    is_deeply( [ sort map $_->Login, @{ $users->ItemsArrayRef } ], ['aurelia', 'ivan'] );
}

{
    my $res = $handle->DeleteFromSelect(
        'UsersToGroups' => 'SELECT id FROM UsersToGroups WHERE GroupId = ?', 1
    );
    is( $res, 2 );

    my $users = TestApp::Users->new( $handle );
    my $alias = $users->Join( FIELD1 => 'id', TABLE2 => 'UsersToGroups', FIELD2 => 'UserId' );
    $users->Limit( ALIAS => $alias, FIELD => 'GroupId', VALUE => 1 );
    is( $users->Count, 0 );
}

{
    my $res = $handle->SimpleUpdateFromSelect(
        'UsersToGroups',
        { UserId => 2, GroupId => 2 },
        'SELECT id FROM UsersToGroups WHERE UserId = ? AND GroupId = ?',
        1, 3
    );
    is( $res, 1 );

    my $u2gs = TestApp::UsersToGroups->new( $handle );
    $u2gs->Limit( FIELD => 'UserId', VALUE => 1 );
    $u2gs->Limit( FIELD => 'GroupId', VALUE => 3 );
    is( $u2gs->Count, 0 );

    $u2gs = TestApp::UsersToGroups->new( $handle );
    $u2gs->Limit( FIELD => 'UserId', VALUE => 2 );
    $u2gs->Limit( FIELD => 'GroupId', VALUE => 2 );
    is( $u2gs->Count, 1 );
}

diag "insert into table from the same table" if $ENV{'TEST_VERBOSE'};
{
    my $res = $handle->InsertFromSelect(
        'UsersToGroups' => ['UserId', 'GroupId'],
        'SELECT GroupId, UserId FROM UsersToGroups',
    );
    is( $res, 2 );
}

diag "insert into table from two tables" if $ENV{'TEST_VERBOSE'};
{ TODO: {
    local $TODO;
    $TODO = "No idea how to make it work on Oracle" if $d eq 'Oracle';
    my $res = do {
        local $handle->dbh->{'PrintError'} = 0;
        local $SIG{__WARN__} = sub {};
        $handle->InsertFromSelect(
            'UsersToGroups' => ['UserId', 'GroupId'],
            'SELECT u.id, g.id FROM Users u, Groups g WHERE u.Login LIKE ? AND g.Name = ?',
            '%a%', 'Support'
        );
    };
    is( $res, 2 );
    my $users = TestApp::Users->new( $handle );
    my $u2g_alias = $users->Join( FIELD1 => 'id', TABLE2 => 'UsersToGroups', FIELD2 => 'UserId' );
    my $g_alias = $users->Join(
        ALIAS1 => $u2g_alias, FIELD1 => 'GroupId', TABLE2 => 'Groups', FIELD2 => 'id',
    );
    $users->Limit( ALIAS => $g_alias, FIELD => 'Name', VALUE => 'Support' );
    is_deeply( [ sort map $_->Login, @{ $users->ItemsArrayRef } ], ['aurelia', 'ivan'] );
} }

    cleanup_schema( 'TestApp', $handle );

}} # SKIP, foreach blocks

1;


package TestApp;
sub schema_sqlite {
[
q{
CREATE TABLE Users (
    id integer primary key,
    Login varchar(36)
) },
q{
CREATE TABLE UsersToGroups (
    id integer primary key,
    UserId  integer,
    GroupId integer
) },
q{
CREATE TABLE Groups (
    id integer primary key,
    Name varchar(36)
) },
]
}

# TEMPORARY tables can not be referenced more than once
# in the same query, use real table for UsersToGroups
sub schema_mysql {
[
q{
CREATE TEMPORARY TABLE Users (
    id integer primary key AUTO_INCREMENT,
    Login varchar(36)
) },
q{
CREATE TABLE UsersToGroups (
    id integer primary key AUTO_INCREMENT,
    UserId  integer,
    GroupId integer
) },
q{
CREATE TEMPORARY TABLE Groups (
    id integer primary key AUTO_INCREMENT,
    Name varchar(36)
) },
]
}

sub cleanup_schema_mysql { [
    "DROP TABLE UsersToGroups", 
] }

sub schema_pg {
[
q{
CREATE TEMPORARY TABLE Users (
    id serial primary key,
    Login varchar(36)
) },
q{
CREATE TEMPORARY TABLE UsersToGroups (
    id serial primary key,
    UserId integer,
    GroupId integer
) },
q{
CREATE TEMPORARY TABLE Groups (
    id serial primary key,
    Name varchar(36)
) },
]
}

sub schema_oracle { [
    "CREATE SEQUENCE Users_seq",
    "CREATE TABLE Users (
        id integer CONSTRAINT Users_Key PRIMARY KEY,
        Login varchar(36)
    )",
    "CREATE SEQUENCE UsersToGroups_seq",
    "CREATE TABLE UsersToGroups (
        id integer CONSTRAINT UsersToGroups_Key PRIMARY KEY,
        UserId integer,
        GroupId integer
    )",
    "CREATE SEQUENCE Groups_seq",
    "CREATE TABLE Groups (
        id integer CONSTRAINT Groups_Key PRIMARY KEY,
        Name varchar(36)
    )",
] }

sub cleanup_schema_oracle { [
    "DROP SEQUENCE Users_seq",
    "DROP TABLE Users", 
    "DROP SEQUENCE Groups_seq",
    "DROP TABLE Groups", 
    "DROP SEQUENCE UsersToGroups_seq",
    "DROP TABLE UsersToGroups", 
] }

package TestApp::Record;

use base $ENV{SB_TEST_CACHABLE}?
    qw/DBIx::SearchBuilder::Record::Cachable/:
    qw/DBIx::SearchBuilder::Record/;

sub _Init {
    my $self = shift;
    my $handle = shift;
    $self->_Handle($handle);

    my $table = ref $self || $self;
    $table =~ s/.*:://;
    $table .= 's';
    $self->Table( $table );
}

package TestApp::Col;
use base 'DBIx::SearchBuilder';

sub _Init {
    my $self = shift;
    $self->SUPER::_Init( Handle => shift );

    my $table = ref $self || $self;
    $table =~ s/.*:://;
    $self->Table( $table );
}

sub NewItem {
    my $self = shift;
    my $record_class = (ref($self) || $self);
    $record_class =~ s/s$//;
    return $record_class->new( $self->_Handle );
}

package TestApp::User;
use base 'TestApp::Record';

sub _ClassAccessible { return {
    id => {read => 1, type => 'int(11)'}, 
    Login => {read => 1, write => 1, type => 'varchar(36)'},
} }

sub init_data {
    return (
    [ 'Login' ],

    [ 'ivan' ],
    [ 'john' ],
    [ 'bob' ],
    [ 'aurelia' ],
    );
}

package TestApp::Group;
use base 'TestApp::Record';

sub _ClassAccessible {
    {
        id => {read => 1, type => 'int(11)'}, 
        Name => {read => 1, write => 1, type => 'varchar(36)'},
    }
}

sub init_data {
    return (
    [ 'Name' ],

    [ 'Developers' ],
    [ 'Sales' ],
    [ 'Support' ],
    );
}

package TestApp::UsersToGroup;
use base 'TestApp::Record';

sub _ClassAccessible {
    return {
        id => {read => 1, type => 'int(11)'}, 
        UserId => {read => 1, type => 'int(11)'}, 
        GroupId => {read => 1, type => 'int(11)'}, 
    }
}

sub init_data {
    return ([ 'GroupId',    'UserId' ]);
}

package TestApp::Users;
use base 'TestApp::Col';

package TestApp::Groups;
use base 'TestApp::Col';

package TestApp::UsersToGroups;
use base 'TestApp::Col';
