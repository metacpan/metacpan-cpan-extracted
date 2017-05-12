#!/usr/bin/perl -w


use strict;
use warnings;
use Test::More;
BEGIN { require "t/utils.pl" }
our (@AvailableDrivers);

use constant TESTS_PER_DRIVER => 11;

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
    unless ( $handle->HasSupportForNullsOrder ) {
        skip "Feature is not supported by $d", TESTS_PER_DRIVER;
    }
    isa_ok($handle->dbh, 'DBI::db');

    my $ret = init_schema( 'TestApp', $handle );
    isa_ok($ret,'DBI::st', "Inserted the schema. got a statement handle back");

    my $count_all = init_data( 'TestApp::User', $handle );
    ok( $count_all,  "init users data" );

	my $users_obj = TestApp::Users->new( $handle );
    $users_obj->UnLimit;

# NULLs are small
    $handle->NullsOrder('small');
    $users_obj->OrderBy(FIELD => 'Value', ORDER => 'ASC' );
    is_deeply
        [ map $_->Value, @{ $users_obj->ItemsArrayRef } ],
        [ undef, 0, 1 ],
    ;
    $users_obj->OrderBy(FIELD => 'Value', ORDER => 'DESC' );
    is_deeply
        [ map $_->Value, @{ $users_obj->ItemsArrayRef } ],
        [ 1, 0, undef ],
    ;

# NULLs are large
    $handle->NullsOrder('large');
    $users_obj->OrderBy(FIELD => 'Value', ORDER => 'ASC' );
    is_deeply
        [ map $_->Value, @{ $users_obj->ItemsArrayRef } ],
        [ 0, 1, undef ],
    ;
    $users_obj->OrderBy(FIELD => 'Value', ORDER => 'DESC' );
    is_deeply
        [ map $_->Value, @{ $users_obj->ItemsArrayRef } ],
        [ undef, 1, 0, ],
    ;

# NULLs are first
    $handle->NullsOrder('first');
    $users_obj->OrderBy(FIELD => 'Value', ORDER => 'ASC' );
    is_deeply
        [ map $_->Value, @{ $users_obj->ItemsArrayRef } ],
        [ undef, 0, 1 ],
    ;
    $users_obj->OrderBy(FIELD => 'Value', ORDER => 'DESC' );
    is_deeply
        [ map $_->Value, @{ $users_obj->ItemsArrayRef } ],
        [ undef, 1, 0, ],
    ;

# NULLs are last
    $handle->NullsOrder('last');
    $users_obj->OrderBy(FIELD => 'Value', ORDER => 'ASC' );
    is_deeply
        [ map $_->Value, @{ $users_obj->ItemsArrayRef } ],
        [ 0, 1, undef ],
    ;
    $users_obj->OrderBy(FIELD => 'Value', ORDER => 'DESC' );
    is_deeply
        [ map $_->Value, @{ $users_obj->ItemsArrayRef } ],
        [ 1, 0, undef ],
    ;

    cleanup_schema( 'TestApp', $handle );
}} # SKIP, foreach blocks

1;

package TestApp;

sub schema_mysql {[
    "DROP TABLE IF EXISTS Users",
<<EOF
CREATE TABLE Users (
    id integer AUTO_INCREMENT,
    Value integer,
    PRIMARY KEY (id)
)
EOF
]}
sub cleanup_schema_mysql { [
    "DROP TABLE Users", 
] }

sub schema_pg {
<<EOF;
CREATE TEMPORARY TABLE Users (
    id serial PRIMARY KEY,
    Value integer
)
EOF

}

sub schema_sqlite {

<<EOF;
CREATE TABLE Users (
    id integer primary key,
    Value integer
)
EOF

}

sub schema_oracle { [
    "CREATE SEQUENCE Users_seq",
    "CREATE TABLE Users (
        id integer CONSTRAINT Users_Key PRIMARY KEY,
        Value integer
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
        Value =>
        {read => 1, write => 1, type => 'int(11)' }, 
    }
}

sub init_data {
    return (
    [ 'Value', ],
    [ undef, ],
    [ 0, ],
    [ 1, ],
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

