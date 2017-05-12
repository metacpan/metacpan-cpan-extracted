#!/usr/bin/perl -w

use strict;
use Test::More;

BEGIN { require "t/utils.pl" }
our (@AvailableDrivers);

use constant TESTS_PER_DRIVER => 18;

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

    my $count_users = init_data( 'TestApp::User', $handle );
    ok( $count_users,  "init users data" );
    my $count_groups = init_data( 'TestApp::Group', $handle );
    ok( $count_groups,  "init groups data" );
    my $count_us2gs = init_data( 'TestApp::UsersToGroup', $handle );
    ok( $count_us2gs,  "init users&groups relations data" );

    my $clean_obj = TestApp::Users->new( $handle );

diag "FUNCTION with ? in Limit" if $ENV{'TEST_VERBOSE'};
{
    my $users_obj = $clean_obj->Clone;
    $users_obj->Limit( FUNCTION => 'SUBSTR(?, 1, 1)', FIELD => 'Login', VALUE => 'I' );
    is( $users_obj->Count, 1, "only one value" );
    is( $users_obj->First->Login, 'Ivan', "ivan is the only match" );
}

diag "make sure case insensitive works" if $ENV{'TEST_VERBOSE'}; 
{
    my $users_obj = $clean_obj->Clone;
    $users_obj->Limit( FUNCTION => 'SUBSTR(?, 1, 1)', FIELD => 'Login', VALUE => 'i' );
    is( $users_obj->Count, 1, "only one value" );
    is( $users_obj->First->Login, 'Ivan', "ivan is the only match" );
}

diag "FUNCTION without ?, but with () in Limit" if $ENV{'TEST_VERBOSE'};
{
    my $users_obj = $clean_obj->Clone;
    $users_obj->Limit( FUNCTION => 'SUBSTR(main.Login, 1, 1)', FIELD => 'Login', VALUE => 'I' );
    is( $users_obj->Count, 1, "only one value" );
    is( $users_obj->First->Login, 'Ivan', "ivan is the only match" );
}

diag "FUNCTION with ? in Column" if $ENV{'TEST_VERBOSE'};
{
    my $users_obj = $clean_obj->Clone;
    $users_obj->UnLimit;
    $users_obj->Column(FIELD => 'id');
    my $alias = $users_obj->Column(FIELD => 'Login', FUNCTION => 'SUBSTR(?, 1, 1)');
    is( $alias, 'Login' );

    is_deeply(
        [sort map $_->Login, @{ $users_obj->ItemsArrayRef } ],
        [sort qw(a B I j)],
        'correct values',
    );
}

diag "FUNCTION without ?, but with () in Column" if $ENV{'TEST_VERBOSE'};
{
    my $users_obj = $clean_obj->Clone;
    $users_obj->UnLimit;
    $users_obj->Column(FIELD => 'id');
    my $alias = $users_obj->Column(FIELD => 'Login', FUNCTION => 'SUBSTR(main.Login, 1, 1)');
    is( $alias, 'Login' );

    is_deeply(
        [sort map $_->Login, @{ $users_obj->ItemsArrayRef } ],
        [sort qw(a B I j)],
        'correct values',
    );
}

diag "NULL FUNCTION in Column" if $ENV{'TEST_VERBOSE'};
{
    my $users_obj = $clean_obj->Clone;
    $users_obj->UnLimit;
    $users_obj->Column(FIELD => 'id');
    $users_obj->Column(FIELD => 'Login', FUNCTION => 'NULL');
    is_deeply(
        [ map $_->Login, @{ $users_obj->ItemsArrayRef } ],
        [(undef)x4],
        'correct values',
    );
}

diag "FUNCTION w/0 ? and () in Column" if $ENV{'TEST_VERBOSE'};
{
    my $users_obj = $clean_obj->Clone;
    $users_obj->UnLimit;
    my $u2g_alias = $users_obj->Join(
        TYPE   => 'LEFT',
        FIELD1 => 'id',
        TABLE2 => 'UsersToGroups',
        FIELD2 => 'UserId',
    );
    $users_obj->GroupBy({FIELD => 'Login'});
    $users_obj->Column(FIELD => 'Login');
    my $column_alias = $users_obj->Column(FIELD => 'id', ALIAS => $u2g_alias, FUNCTION => 'COUNT');
    isnt( $column_alias, 'id' );

    is_deeply(
        { map { $_->Login => $_->_Value($column_alias) } @{ $users_obj->ItemsArrayRef } },
        { Ivan => 2, john => 1, Bob => 0, aurelia => 1 },
        'correct values',
    );
}

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

sub schema_mysql {
[
q{
CREATE TEMPORARY TABLE Users (
    id integer primary key AUTO_INCREMENT,
    Login varchar(36)
) },
q{
CREATE TEMPORARY TABLE UsersToGroups (
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

package TestApp::User;

use base $ENV{SB_TEST_CACHABLE}?
    qw/DBIx::SearchBuilder::Record::Cachable/:
    qw/DBIx::SearchBuilder::Record/;

sub _Init {
    my $self = shift;
    my $handle = shift;
    $self->Table('Users');
    $self->_Handle($handle);
}

sub _ClassAccessible {
    {   
        
        id =>
        {read => 1, type => 'int(11)'}, 
        Login => 
        {read => 1, write => 1, type => 'varchar(36)'},

    }
}

sub init_data {
    return (
    [ 'Login' ],

    [ 'Ivan' ],
    [ 'john' ],
    [ 'Bob' ],
    [ 'aurelia' ],
    );
}

package TestApp::Users;

use base qw/DBIx::SearchBuilder/;

sub _Init {
    my $self = shift;
    $self->SUPER::_Init( Handle => shift );
    $self->Table('Users');
}

sub NewItem
{
    my $self = shift;
    return TestApp::User->new( $self->_Handle );
}

1;

package TestApp::Group;

use base $ENV{SB_TEST_CACHABLE}?
    qw/DBIx::SearchBuilder::Record::Cachable/:
    qw/DBIx::SearchBuilder::Record/;

sub _Init {
    my $self = shift;
    my $handle = shift;
    $self->Table('Groups');
    $self->_Handle($handle);
}

sub _ClassAccessible {
    {   
        id =>
        {read => 1, type => 'int(11)'}, 
        Name => 
        {read => 1, write => 1, type => 'varchar(36)'},
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

package TestApp::Groups;

use base qw/DBIx::SearchBuilder/;

sub _Init {
    my $self = shift;
    $self->SUPER::_Init( Handle => shift );
    $self->Table('Groups');
}

sub NewItem { return TestApp::Group->new( (shift)->_Handle ) }

1;

package TestApp::UsersToGroup;

use base $ENV{SB_TEST_CACHABLE}?
    qw/DBIx::SearchBuilder::Record::Cachable/:
    qw/DBIx::SearchBuilder::Record/;

sub _Init {
    my $self = shift;
    my $handle = shift;
    $self->Table('UsersToGroups');
    $self->_Handle($handle);
}

sub _ClassAccessible {
    {   
        
        id =>
        {read => 1, type => 'int(11)'}, 
        UserId =>
        {read => 1, type => 'int(11)'}, 
        GroupId =>
        {read => 1, type => 'int(11)'}, 
    }
}

sub init_data {
    return (
    [ 'GroupId',    'UserId' ],
# dev group
    [ 1,        1 ],
    [ 1,        2 ],
    [ 1,        4 ],
# sales
#    [ 2,        0 ],
# support
    [ 3,        1 ],
    );
}

package TestApp::UsersToGroups;

use base qw/DBIx::SearchBuilder/;

sub _Init {
    my $self = shift;
    $self->Table('UsersToGroups');
    return $self->SUPER::_Init( Handle => shift );
}

sub NewItem { return TestApp::UsersToGroup->new( (shift)->_Handle ) }

1;
