#!/usr/bin/perl -w

use strict;
use Test::More;

BEGIN { require "t/utils.pl" }
our (@AvailableDrivers);

use constant TESTS_PER_DRIVER => 59;

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
    my $users_obj = $clean_obj->Clone;
    is_deeply( $users_obj, $clean_obj, 'after Clone looks the same');

diag "inner JOIN with ->Join method" if $ENV{'TEST_VERBOSE'};
{
    ok( !$users_obj->_isJoined, "new object isn't joined");
    my $alias = $users_obj->Join(
        FIELD1 => 'id',
        TABLE2 => 'UsersToGroups',
        FIELD2 => 'UserId'
    );
    ok( $alias, "Join returns alias" );
    TODO: {
        local $TODO = "is joined doesn't mean is limited, count returns 0";
        is( $users_obj->Count, 3, "three users are members of the groups" );
    }
    # fake limit to check if join actually joins
    $users_obj->Limit( FIELD => 'id', OPERATOR => 'IS NOT', VALUE => 'NULL' );
    is( $users_obj->Count, 3, "three users are members of the groups" );
}

diag "LEFT JOIN with ->Join method" if $ENV{'TEST_VERBOSE'}; 
{
    $users_obj->CleanSlate;
    is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
    ok( !$users_obj->_isJoined, "new object isn't joined");
    my $alias = $users_obj->Join(
        TYPE   => 'LEFT',
        FIELD1 => 'id',
        TABLE2 => 'UsersToGroups',
        FIELD2 => 'UserId'
    );
    ok( $alias, "Join returns alias" );
    $users_obj->Limit( ALIAS => $alias, FIELD => 'id', OPERATOR => 'IS', VALUE => 'NULL' );
    ok( $users_obj->BuildSelectQuery =~ /LEFT JOIN/, 'LJ is not optimized away');
    is( $users_obj->Count, 1, "user is not member of any group" );
    is( $users_obj->First->id, 3, "correct user id" );
}

diag "LEFT JOIN with IS NOT NULL on the right side" if $ENV{'TEST_VERBOSE'}; 
{
    $users_obj->CleanSlate;
    is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
    ok( !$users_obj->_isJoined, "new object isn't joined");
    my $alias = $users_obj->Join(
        TYPE   => 'LEFT',
        FIELD1 => 'id',
        TABLE2 => 'UsersToGroups',
        FIELD2 => 'UserId'
    );
    ok( $alias, "Join returns alias" );
    $users_obj->Limit( ALIAS => $alias, FIELD => 'id', OPERATOR => 'IS NOT', VALUE => 'NULL' );
    ok( $users_obj->BuildSelectQuery !~ /LEFT JOIN/, 'LJ is optimized away');
    is( $users_obj->Count, 3, "users whos is memebers of at least one group" );
}

diag "LEFT JOIN with ->Join method and using alias" if $ENV{'TEST_VERBOSE'};
{
    $users_obj->CleanSlate;
    is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
    ok( !$users_obj->_isJoined, "new object isn't joined");
    my $alias = $users_obj->NewAlias( 'UsersToGroups' );
    ok( $alias, "new alias" );
    is($users_obj->Join(
            TYPE   => 'LEFT',
            FIELD1 => 'id',
            ALIAS2 => $alias,
            FIELD2 => 'UserId' ),
        $alias, "joined table"
    );
    $users_obj->Limit( ALIAS => $alias, FIELD => 'id', OPERATOR => 'IS', VALUE => 'NULL' );
    ok( $users_obj->BuildSelectQuery =~ /LEFT JOIN/, 'LJ is not optimized away');
    is( $users_obj->Count, 1, "user is not member of any group" );
}

diag "main <- alias <- join" if $ENV{'TEST_VERBOSE'};
{
    # The join depends on the alias, we should build joins with correct order.
    $users_obj->CleanSlate;
    is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
    ok( !$users_obj->_isJoined, "new object isn't joined");
    my $alias = $users_obj->NewAlias( 'UsersToGroups' );
    ok( $alias, "new alias" );
    ok( $users_obj->_isJoined, "object with aliases is joined");
    $users_obj->Limit( FIELD => 'id', VALUE => "$alias.UserId", QUOTEVALUE => 0);
    ok( my $groups_alias = $users_obj->Join(
            ALIAS1 => $alias,
            FIELD1 => 'GroupId',
            TABLE2 => 'Groups',
            FIELD2 => 'id',
        ),
        "joined table"
    );
    $users_obj->Limit( ALIAS => $groups_alias, FIELD => 'Name', VALUE => 'Developers' );
    is( $users_obj->Count, 3, "three members" );
}

diag "main <- alias <- join into main" if $ENV{'TEST_VERBOSE'};
{
    # DBs' parsers don't like: FROM X, Y JOIN C ON C.f = X.f
    $users_obj->CleanSlate;
    is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
    ok( !$users_obj->_isJoined, "new object isn't joined");

    ok( my $groups_alias = $users_obj->NewAlias( 'Groups' ), "new alias" );
    ok( my $g2u_alias = $users_obj->Join(
            ALIAS1 => 'main',
            FIELD1 => 'id',
            TABLE2 => 'UsersToGroups',
            FIELD2 => 'UserId',
        ),
        "joined table"
    );
    $users_obj->Limit( ALIAS => $g2u_alias, FIELD => 'GroupId', VALUE => "$groups_alias.id", QUOTEVALUE => 0);
    $users_obj->Limit( ALIAS => $groups_alias, FIELD => 'Name', VALUE => 'Developers' );
    #diag $users_obj->BuildSelectQuery;
    is( $users_obj->Count, 3, "three members" );
}

diag "cascaded LEFT JOIN optimization" if $ENV{'TEST_VERBOSE'}; 
{
    $users_obj->CleanSlate;
    is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
    ok( !$users_obj->_isJoined, "new object isn't joined");
    my $alias = $users_obj->Join(
        TYPE   => 'LEFT',
        FIELD1 => 'id',
        TABLE2 => 'UsersToGroups',
        FIELD2 => 'UserId'
    );
    ok( $alias, "Join returns alias" );
    $alias = $users_obj->Join(
        TYPE   => 'LEFT',
        ALIAS1 => $alias,
        FIELD1 => 'GroupId',
        TABLE2 => 'Groups',
        FIELD2 => 'id'
    );
    $users_obj->Limit( ALIAS => $alias, FIELD => 'id', OPERATOR => 'IS NOT', VALUE => 'NULL' );
    ok( $users_obj->BuildSelectQuery !~ /LEFT JOIN/, 'both LJs are optimized away');
    is( $users_obj->Count, 3, "users whos is memebers of at least one group" );
}

diag "LEFT JOIN optimization and OR clause" if $ENV{'TEST_VERBOSE'}; 
{
    $users_obj->CleanSlate;
    is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
    ok( !$users_obj->_isJoined, "new object isn't joined");
    my $alias = $users_obj->Join(
        TYPE   => 'LEFT',
        FIELD1 => 'id',
        TABLE2 => 'UsersToGroups',
        FIELD2 => 'UserId'
    );
    $users_obj->_OpenParen('my_clause');
    $users_obj->Limit(
        SUBCLAUSE => 'my_clause',
        ALIAS => $alias,
        FIELD => 'id',
        OPERATOR => 'IS NOT',
        VALUE => 'NULL'
    );
    $users_obj->Limit(
        SUBCLAUSE => 'my_clause',
        ENTRY_AGGREGATOR => 'OR',
        FIELD => 'id',
        VALUE => 3
    );
    $users_obj->_CloseParen('my_clause');
    ok( $users_obj->BuildSelectQuery =~ /LEFT JOIN/, 'LJ is not optimized away');
    is( $users_obj->Count, 4, "all users" );
}

diag "DISTINCT in Join" if $ENV{'TEST_VERBOSE'};
{
    $users_obj->CleanSlate;
    is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
    ok( !$users_obj->_isJoined, "new object isn't joined");
    my $alias = $users_obj->Join(
        FIELD1 => 'id',
        TABLE2 => 'UsersToGroups',
        FIELD2 => 'UserId',
        DISTINCT => 1,
    );
    $users_obj->Limit(
        ALIAS => $alias,
        FIELD => 'GroupId',
        VALUE => 1,
    );
    ok( $users_obj->BuildSelectQuery !~ /DISTINCT|GROUP\s+BY/i, 'no distinct in SQL');
    is_deeply(
        [ sort map $_->Login, @{$users_obj->ItemsArrayRef} ],
        [ 'aurelia', 'ivan', 'john' ],
        "members of dev group"
    );
}

diag "DISTINCT in NewAlias" if $ENV{'TEST_VERBOSE'};
{
    $users_obj->CleanSlate;
    is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
    ok( !$users_obj->_isJoined, "new object isn't joined");
    my $alias = $users_obj->NewAlias('UsersToGroups', DISTINCT => 1);
    $users_obj->Join(
        FIELD1 => 'id',
        ALIAS2 => $alias,
        FIELD2 => 'UserId',
    );
    $users_obj->Limit(
        ALIAS => $alias,
        FIELD => 'GroupId',
        VALUE => 1,
    );
    ok( $users_obj->BuildSelectQuery !~ /DISTINCT|GROUP\s+BY/i, 'no distinct in SQL');
    is_deeply(
        [ sort map $_->Login, @{$users_obj->ItemsArrayRef} ],
        [ 'aurelia', 'ivan', 'john' ],
        "members of dev group"
    );
}

diag "mixing DISTINCT" if $ENV{'TEST_VERBOSE'};
{
    $users_obj->CleanSlate;
    is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
    ok( !$users_obj->_isJoined, "new object isn't joined");
    my $u2g_alias = $users_obj->Join(
        FIELD1 => 'id',
        TABLE2 => 'UsersToGroups',
        FIELD2 => 'UserId',
        DISTINCT => 0,
    );
    my $g_alias = $users_obj->Join(
        ALIAS1 => $u2g_alias,
        FIELD1 => 'GroupId',
        TABLE2 => 'Groups',
        FIELD2 => 'id',
        DISTINCT => 1,
    );

    $users_obj->Limit(
        ALIAS => $g_alias,
        FIELD => 'Name',
        VALUE => 'Developers',
    );
    $users_obj->Limit(
        ALIAS => $g_alias,
        FIELD => 'Name',
        VALUE => 'Sales',
    );
    ok( $users_obj->BuildSelectQuery =~ /DISTINCT|GROUP\s+BY/i, 'distinct in SQL');
    is_deeply(
        [ sort map $_->Login, @{$users_obj->ItemsArrayRef} ],
        [ 'aurelia', 'ivan', 'john' ],
        "members of dev group"
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

    [ 'ivan' ],
    [ 'john' ],
    [ 'bob' ],
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
