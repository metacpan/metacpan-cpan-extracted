#!/usr/bin/perl -w


use strict;
use warnings;
use Test::More;
BEGIN { require "t/utils.pl" }
our (@AvailableDrivers);

use constant TESTS_PER_DRIVER => 9;

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
    diag "testing $d" if $ENV{TEST_VERBOSE};

    my $handle = get_handle( $d );
    connect_handle( $handle );
    isa_ok($handle->dbh, 'DBI::db');

    my $ret = init_schema( 'TestApp', $handle );
    isa_ok($ret,'DBI::st', "Inserted the schema. got a statement handle back");

    my $count_all = init_data( 'TestApp::User', $handle );
    ok( $count_all,  "init users data" );

    my $users_obj = TestApp::Users->new( $handle );
    isa_ok( $users_obj, 'DBIx::SearchBuilder' );
    is( $users_obj->_Handle, $handle, "same handle as we used in constructor");

# unlimit new object and check
    $users_obj->UnLimit;
    {
        my @list = qw(boss dev sales);
        if ( $d eq 'Pg' || $d eq 'Oracle' ) {
            push @list, undef;
        } else {
            unshift @list, undef;
        }
        is_deeply(
            [$users_obj->DistinctFieldValues('GroupName', Order => 'ASC')],
            [@list],
            'Correct list'
        );
        is_deeply(
            [$users_obj->DistinctFieldValues('GroupName', Order => 'DESC')],
            [reverse @list],
            'Correct list'
        );
        $users_obj->CleanSlate;
    }

    $users_obj->Limit( FIELD => 'Login', OPERATOR => 'LIKE', VALUE => 'k' );
    is_deeply(
        [$users_obj->DistinctFieldValues('GroupName', Order => 'ASC')],
        [qw(dev sales)],
        'Correct list'
    );
    is_deeply(
        [$users_obj->DistinctFieldValues('GroupName', Order => 'DESC')],
        [reverse qw(dev sales)],
        'Correct list'
    );

    cleanup_schema( 'TestApp', $handle );
}} # SKIP, foreach blocks

1;

package TestApp;

sub schema_mysql {
<<EOF;
CREATE TEMPORARY TABLE Users (
        id integer AUTO_INCREMENT,
        Login varchar(18) NOT NULL,
        GroupName varchar(36),
  	PRIMARY KEY (id))
EOF

}

sub schema_pg {
<<EOF;
CREATE TEMPORARY TABLE Users (
        id serial PRIMARY KEY,
        Login varchar(18) NOT NULL,
        GroupName varchar(36)
)
EOF

}

sub schema_sqlite {

<<EOF;
CREATE TABLE Users (
	id integer primary key,
	Login varchar(18) NOT NULL,
	GroupName varchar(36)
)
EOF

}

sub schema_oracle { [
    "CREATE SEQUENCE Users_seq",
    "CREATE TABLE Users (
        id integer CONSTRAINT Users_Key PRIMARY KEY,
        Login varchar(18) NOT NULL,
        GroupName varchar(36)
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
        Login =>
        {read => 1, write => 1, type => 'varchar(18)' },
        GroupName =>
        {read => 1, write => 1, type => 'varchar(36)' },
    }
}

sub init_data {
    return (
	[ 'Login',	'GroupName' ],
	[ 'cubic',	'dev' ],
	[ 'obra',	'boss' ],
	[ 'kevin',	'dev' ],
	[ 'keri',	'sales' ],
	[ 'some',	undef ],
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
