#!/usr/bin/perl -w

BEGIN { $ENV{'TZ'} = 'Europe/Moscow' };

use strict;
use warnings;
use Test::More;
BEGIN { require "t/utils.pl" }
our (@AvailableDrivers);

use constant TESTS_PER_DRIVER => 17;

my $total = scalar(@AvailableDrivers) * TESTS_PER_DRIVER;
plan tests => $total;

my $handle;

foreach my $d ( @AvailableDrivers ) {
SKIP: {
    unless( has_schema( 'TestApp', $d ) ) {
        skip "No schema for '$d' driver", TESTS_PER_DRIVER;
    }
    unless( should_test( $d ) ) {
        skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
    }

    $handle = get_handle( $d );
    connect_handle( $handle );
    isa_ok($handle->dbh, 'DBI::db');

    diag "testing $d" if $ENV{'TEST_VERBOSE'};

    my $ret = init_schema( 'TestApp', $handle );
    isa_ok($ret,'DBI::st', "Inserted the schema. got a statement handle back");

    my $count_all = init_data( 'TestApp::User', $handle );
    ok( $count_all,  "init users data" );

    my $users = TestApp::Users->new( $handle );
    $users->UnLimit;
    $users->Column( FIELD => 'Result' );
    my $column = $users->Column(
        FUNCTION => $users->_Handle->DateTimeIntervalFunction( From => 'Created', To => 'Resolved' ),
    );

    while ( my $user = $users->Next ) {
        is $user->__Value( $column ), $user->Result;
    }

    $users = TestApp::Users->new( $handle );
    $users->UnLimit;
    $users->Column( FIELD => 'Result' );
    $column = $users->Column(
        FUNCTION => $users->_Handle->DateTimeIntervalFunction(
            From => { FIELD => 'Created' }, To => { FIELD => 'Resolved' },
        ),
    );

    while ( my $user = $users->Next ) {
        is $user->__Value( $column ), $user->Result;
    }

    cleanup_schema( 'TestApp', $handle );
}} # SKIP, foreach blocks

1;

package TestApp;

sub schema_mysql {
<<EOF;
CREATE TEMPORARY TABLE Users (
    id integer AUTO_INCREMENT,
    Created DATETIME NULL,
    Resolved DATETIME NULL,
    Result integer NULL,
    PRIMARY KEY (id)
)
EOF

}

sub schema_pg {
<<EOF;
CREATE TEMPORARY TABLE Users (
    id serial PRIMARY KEY,
    Created TIMESTAMP NULL,
    Resolved TIMESTAMP NULL,
    Result integer NULL
)
EOF

}

sub schema_sqlite {

<<EOF;
CREATE TABLE Users (
    id integer primary key,
    Created TEXT NULL,
    Resolved TEXT NULL,
    Result integer NULL
)
EOF

}

sub schema_oracle { [
    "CREATE SEQUENCE Users_seq",
    "CREATE TABLE Users (
        id integer CONSTRAINT Users_Key PRIMARY KEY,
        Created DATE NULL,
        Resolved DATE NULL,
        Result integer NULL
    )",
] }

sub cleanup_schema_oracle { [
    "DROP SEQUENCE Users_seq",
    "DROP TABLE Users",
] }


1;

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
        {read => 1, type => 'int(11)' }, 
        Created =>
        {read => 1, write => 1, type => 'datetime' },
        Resolved =>
        {read => 1, write => 1, type => 'datetime' },
        Result =>
        {read => 1, type => 'int(11)' }, 
    }
}

sub init_data {
    return (
    [ 'Created',             'Resolved',           'Result'  ],
    [ undef,                 undef                , undef ],
    [ undef                , '2011-05-20 19:53:23', undef ],
    [ '2011-05-20 19:53:23', undef                , undef ],
    [ '2011-05-20 19:53:23', '2011-05-20 19:53:23', 0],
    [ '2011-05-20 19:53:23', '2011-05-21 20:54:24', 1*24*60*60+1*60*60+1*60+1],
    [ '2011-05-20 19:53:23', '2011-05-19 18:52:22', -(1*24*60*60+1*60*60+1*60+1)],
    [ '2011-05-20 19:53:23', '2012-09-20 19:53:23', 42249600],
    );
}

1;

package TestApp::Users;

# use TestApp::User;
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


