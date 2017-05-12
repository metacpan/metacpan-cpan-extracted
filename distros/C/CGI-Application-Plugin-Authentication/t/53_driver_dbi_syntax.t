#!/usr/bin/perl
use Test::More;
use Test::Exception;
use Test::Warn;
use lib qw(t);
eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite required for this test" if $@;

plan tests => 2;

use strict;
use warnings;

our $DBNAME = 't/sqlite.db';

unlink $DBNAME if -e $DBNAME;
my $dbh = DBI->connect( "dbi:SQLite:dbname=$DBNAME", "", "" );

$dbh->do(<<"");
CREATE TABLE user (
    name VARCHAR(20),
    password VARCHAR(50)
)

$dbh->do(<<"");
INSERT INTO user VALUES ('user1', '123');

$dbh->do(<<"");
INSERT INTO user VALUES ('user2', 'mQPVY1HNg8SJ2');  # crypt("123", "mQ")


{

    package TestAppDriverDBISimple;

    use base qw(TestAppDriver);

    __PACKAGE__->authen->config(
        DRIVER => [
            [
                'DBI',
                DBH         => $dbh,
                TABLE       => 'user',
		JOIN_ON     => ' blah blah blah',
                CONSTRAINTS => { 'user.name' => '__CREDENTIAL_1__', 'user.password' => '__CREDENTIAL_2__' },
            ],
        ],
        STORE => 'Store::Dummy',
    );

}

$ENV{CGI_APP_RETURN_ONLY} = 1;

my $params = {
    authen_username => 'user1',
    authen_password => '123',
    rm => 'protected',
};
my $query = CGI->new( $params );
my $cgiapp = TestAppDriverDBISimple->new( QUERY => $query );
warning_like {throws_ok {$cgiapp->run;}
    qr/Error executing class callback in prerun stage: Failed to prepare SQL statement:  near "blah": syntax error/,
    'Syntax error';}
    qr/DBD::SQLite::db prepare_cached failed: near "blah": syntax error/,
    'checking warnings';



$dbh->do(<<"");
DROP TABLE user;


undef $dbh;

unlink $DBNAME if -e $DBNAME;





