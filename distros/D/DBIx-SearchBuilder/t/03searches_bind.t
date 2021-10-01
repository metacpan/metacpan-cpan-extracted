use strict;
use Test::More;

BEGIN { require "./t/utils.pl" }
our (@AvailableDrivers);

use constant TESTS_PER_DRIVER => 39;

my $total = scalar(@AvailableDrivers) * TESTS_PER_DRIVER;
plan tests => $total;

foreach my $d (@AvailableDrivers) {
SKIP: {
        unless ( has_schema( 'TestApp', $d ) ) {
            skip "No schema for '$d' driver", TESTS_PER_DRIVER;
        }
        unless ( should_test($d) ) {
            skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
        }

        my $handle = get_handle($d);
        connect_handle($handle);
        isa_ok( $handle->dbh, 'DBI::db' );

        my $ret = init_schema( 'TestApp', $handle );
        isa_ok( $ret, 'DBI::st', "Inserted the schema. got a statement handle back" );

        my $count_users = init_data( 'TestApp::User', $handle );
        ok( $count_users, "init users data" );
        my $count_groups = init_data( 'TestApp::Group', $handle );
        ok( $count_groups, "init groups data" );
        my $count_us2gs = init_data( 'TestApp::UsersToGroup', $handle );
        ok( $count_us2gs, "init users&groups relations data" );

        my $clean_obj = TestApp::Users->new($handle);

        local $DBIx::SearchBuilder::PREFER_BIND = 1;

        my $users_obj = $clean_obj->Clone;
        for my $login ( 'Gandalf', "Bilbo\\Baggins", "Baggins' Frodo" ) {
            $users_obj->Limit( FIELD => 'Login', VALUE => $login );
            is( $users_obj->Count,        1,      "only one value" );
            is( $users_obj->First->Login, $login, "$login is the only match" );

            # Using \W here because Login might be wrapped in LOWER().
            ok( $users_obj->BuildSelectQuery =~ /Login\W*=\s*\?/i,
                'found a placeholder in select query' );
            ok( $users_obj->BuildSelectCountQuery =~ /Login\W*=\s*\?/i,
                'found a placeholder in select count query'
              );
            $users_obj->CleanSlate;
        }

        $users_obj->Limit(
            FIELD    => 'Login',
            VALUE    => [ "Bilbo\\Baggins", "Baggins' Frodo" ],
            OPERATOR => 'IN',
        );
        is( $users_obj->Count, 2, "2 values" );
        is_deeply(
            [ sort map { $_->Login } @{ $users_obj->ItemsArrayRef } ],
            [ "Baggins' Frodo", "Bilbo\\Baggins" ],
            '2 Baggins',
        );
        $users_obj->CleanSlate;

        for my $name ( "Shire's Bag End", 'The Fellowship of the Ring' ) {
            my $groups_obj = TestApp::Groups->new($handle);
            $groups_obj->Limit( FIELD => 'Name', VALUE => $name, OPERATOR => 'LIKE' );
            $groups_obj->Limit( FIELD => 'id',   VALUE => 0,     OPERATOR => '>' );
            is( $groups_obj->Count,       1,     "only one value" );
            is( $groups_obj->First->Name, $name, "$name is the only match" );

            # Using \W here because Login might be wrapped in LOWER().
            ok( $groups_obj->BuildSelectQuery =~ /Name\W*I?LIKE\s*\?/i,
                'found a placeholder for Name in select query'
              );
            ok( $groups_obj->BuildSelectQuery =~ /id\s*>\s*\?/i,
                'found a placeholder for id in select query'
              );
            ok( $groups_obj->BuildSelectCountQuery =~ /Name\W*I?LIKE\s*\?/i,
                'found a placeholder for Name in select count query'
              );
            ok( $groups_obj->BuildSelectCountQuery =~ /id\s*>\s*\?/i,
                'found a placeholder for id in select count query'
              );
        }

        my $alias = $users_obj->Join(
            FIELD1 => 'id',
            TABLE2 => 'UsersToGroups',
            FIELD2 => 'UserId'
        );

        my $group_alias = $users_obj->Join(
            ALIAS1 => $alias,
            FIELD1 => 'GroupID',
            ALIAS2 => $users_obj->NewAlias('Groups'),
            FIELD2 => 'id'
        );
        $users_obj->Limit(
            LEFTJOIN => $group_alias,
            FIELD    => 'Name',
            VALUE    => "Shire's Bag End",
        );

        is( $users_obj->Count, 2, "2 values" );
        is_deeply(
            [ sort map { $_->Login } @{ $users_obj->ItemsArrayRef } ],
            [ "Baggins' Frodo", "Bilbo\\Baggins" ],
            '2 Baggins',
        );

        # ? in JOIN condition
        ok( $users_obj->BuildSelectQuery( PreferBind => 0 ) !~ /\?/,
            'found placeholder in select query' );
        ok( $users_obj->BuildSelectCountQuery( PreferBind => 0 ) !~ /\?/,
            'found placeholder in select count query' );

        ok( $users_obj->BuildSelectQuery( PreferBind => 0 ) !~ /\?/,
            'no placeholder in select query' );
        ok( $users_obj->BuildSelectCountQuery( PreferBind => 0 ) !~ /\?/,
            'no placeholder in select count query' );

        $DBIx::SearchBuilder::PREFER_BIND = 0;
        ok( $users_obj->BuildSelectQuery      !~ /\?/, 'no placeholder in select query' );
        ok( $users_obj->BuildSelectCountQuery !~ /\?/, 'no placeholder in select count query' );

        cleanup_schema( 'TestApp', $handle );

    }
}    # SKIP, foreach blocks

1;

package TestApp;

sub schema_sqlite {
    [   q{
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
    [   q{
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
CREATE TEMPORARY TABLE `Groups` (
    id integer primary key AUTO_INCREMENT,
    Name varchar(36)
) },
    ]
}

sub schema_pg {
    [   q{
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

sub schema_oracle {
    [   "CREATE SEQUENCE Users_seq",
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
    ]
}

sub cleanup_schema_oracle {
    [   "DROP SEQUENCE Users_seq",
        "DROP TABLE Users",
        "DROP SEQUENCE Groups_seq",
        "DROP TABLE Groups",
        "DROP SEQUENCE UsersToGroups_seq",
        "DROP TABLE UsersToGroups",
    ]
}

package TestApp::User;

use base $ENV{SB_TEST_CACHABLE}
    ? qw/DBIx::SearchBuilder::Record::Cachable/
    : qw/DBIx::SearchBuilder::Record/;

sub _Init {
    my $self   = shift;
    my $handle = shift;
    $self->Table('Users');
    $self->_Handle($handle);
}

sub _ClassAccessible {
    {

        id    => { read => 1, type  => 'int(11)' },
        Login => { read => 1, write => 1, type => 'varchar(36)' },

    }
}

sub init_data {
    return (
        ['Login'],

        ['Gandalf'],
        ["Bilbo\\Baggins"],
        ["Baggins' Frodo"],
    );
}

package TestApp::Users;

use base qw/DBIx::SearchBuilder/;

sub _Init {
    my $self = shift;
    $self->SUPER::_Init( Handle => shift );
    $self->Table('Users');
}

sub NewItem {
    my $self = shift;
    return TestApp::User->new( $self->_Handle );
}

1;

package TestApp::Group;

use base $ENV{SB_TEST_CACHABLE}
    ? qw/DBIx::SearchBuilder::Record::Cachable/
    : qw/DBIx::SearchBuilder::Record/;

sub _Init {
    my $self   = shift;
    my $handle = shift;
    $self->Table('Groups');
    $self->_Handle($handle);
}

sub _ClassAccessible {
    {   id   => { read => 1, type  => 'int(11)' },
        Name => { read => 1, write => 1, type => 'varchar(36)' },
    }
}

sub init_data {
    return (
        ['Name'],

        ["Shire's Bag End"],
        ['The Fellowship of the Ring'],
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

use base $ENV{SB_TEST_CACHABLE}
    ? qw/DBIx::SearchBuilder::Record::Cachable/
    : qw/DBIx::SearchBuilder::Record/;

sub _Init {
    my $self   = shift;
    my $handle = shift;
    $self->Table('UsersToGroups');
    $self->_Handle($handle);
}

sub _ClassAccessible {
    {

        id      => { read => 1, type => 'int(11)' },
        UserId  => { read => 1, type => 'int(11)' },
        GroupId => { read => 1, type => 'int(11)' },
    }
}

sub init_data {
    return (
        [ 'GroupId', 'UserId' ],

        # Shire
        [ 1, 2 ],
        [ 1, 3 ],

        # Fellowship of the Ring
        [ 2, 1 ],
        [ 2, 3 ],
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
