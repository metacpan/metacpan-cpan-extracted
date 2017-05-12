#!/usr/bin/perl
use Test::More;
use lib qw(t);
eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite required for this test" if $@;

plan tests => 90;

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
                CONSTRAINTS => { 'user.name' => '__CREDENTIAL_1__', 'user.password' => '__CREDENTIAL_2__' },
            ],
            [
                'DBI',
                DBH         => $dbh,
                TABLES      => 'user',
                COLUMNS     => { 'crypt:user.password' => '__CREDENTIAL_2__' },
                CONSTRAINTS => { 'user.name' => '__CREDENTIAL_1__' },
            ],
        ],
        STORE => 'Store::Dummy',
    );

}

TestAppDriverDBISimple->run_authen_tests(
    [ 'authen_username', 'authen_password' ],
    [ 'user1', '123' ],
    [ 'user2', '123' ],
);

$dbh->do(<<"");
DROP TABLE user;



#
# MULTIPLE TABLES
#
$dbh->do(<<"");
CREATE TABLE domain (
    id INTEGER,
    name VARCHAR(20)
);

$dbh->do(<<"");
CREATE TABLE user (
    id INTEGER,
    domainid INTEGER,
    name VARCHAR(20),
    password VARCHAR(50)
)

$dbh->do(<<"");
INSERT INTO domain VALUES (1, 'domain1');

$dbh->do(<<"");
INSERT INTO domain VALUES (2, 'domain2');

$dbh->do(<<"");
INSERT INTO user VALUES (1, 1, 'user1', '123');

$dbh->do(<<"");
INSERT INTO user VALUES (2, 2, 'user1', '234');

$dbh->do(<<"");
INSERT INTO user VALUES (3, 1, 'user2', '345');

$dbh->do(<<"");
INSERT INTO user VALUES (4, 1, 'user3', 'mQPVY1HNg8SJ2');  # crypt("123", "mQ")


{

    package TestAppDriverDBIMultiTable;

    use base qw(TestAppDriver);

    __PACKAGE__->authen->config(
        DRIVER => [
            [
                'DBI',
                DBH         => $dbh,
                TABLES      => [ 'user', 'domain' ],
                JOIN_ON     => 'user.domainid = domain.id',
                CONSTRAINTS => { 'user.name' => '__CREDENTIAL_1__', 'user.password' => '__CREDENTIAL_2__', 'domain.name' => '__CREDENTIAL_3__' }
            ],
            [
                'DBI',
                DBH         => $dbh,
                TABLES      => [ 'user', 'domain' ],
                JOIN_ON     => 'user.domainid = domain.id',
                COLUMNS     => { 'user.password' => '__CREDENTIAL_3__', 'domain.name' => '__CREDENTIAL_2__' },
                CONSTRAINTS => { 'user.name' => '__CREDENTIAL_1__' }
            ],
        ],
        STORE       => 'Store::Dummy',
        CREDENTIALS => [qw(username password domain)],
    );

}

TestAppDriverDBIMultiTable->run_authen_tests(
    [ 'username', 'password', 'domain' ],
    [ 'user1', '123', 'domain1' ],
    [ 'user1', '234', 'domain2' ],
    [ 'user1', 'domain1', '123' ],
    [ 'user1', 'domain2', '234' ],
);

$dbh->do(<<"");
DROP TABLE domain;

$dbh->do(<<"");
DROP TABLE user;





#
# ENCODED FIELDS
#
$dbh->do(<<"");
CREATE TABLE user (
    name VARCHAR(20),
    password VARCHAR(50)
)

$dbh->do(<<"");
INSERT INTO user VALUES ('user1', 'mQPVY1HNg8SJ2');  # crypt("123", "mQ")

$dbh->do(<<"");
INSERT INTO user VALUES ('user2', '202cb962ac59075b964b07152d234b70');  # md5_hex("123")


{

    package TestAppDriverDBIEncode;

    use base qw(TestAppDriver);

    __PACKAGE__->authen->config(
        DRIVER => [
            [
                'DBI',
                DBH         => $dbh,
                TABLE       => 'user',
                COLUMNS     => { 'crypt:password' => '__CREDENTIAL_2__' },
                CONSTRAINTS => { 'user.name' => '__CREDENTIAL_1__' }
            ],
            [
                'DBI',
                DBH         => $dbh,
                TABLE       => 'user',
                CONSTRAINTS => { 'user.name' => '__CREDENTIAL_1__', 'MD5:password' => '__CREDENTIAL_2__' }
            ],
        ],
        STORE       => 'Store::Dummy',
        CREDENTIALS => [qw(username password)],
    );

}

TestAppDriverDBIEncode->run_authen_tests(
    [ 'username', 'password' ],
    [ 'user1', '123' ],
    [ 'user2', '123' ],
);

$dbh->do(<<"");
DROP TABLE user;




#
# ENCODED FIELDS
#
$dbh->do(<<"");
CREATE TABLE user (
    name VARCHAR(20),
    password VARCHAR(50),
    active INTEGER
)

$dbh->do(<<"");
INSERT INTO user VALUES ('user1', '123', 1);

$dbh->do(<<"");
INSERT INTO user VALUES ('user2', '123', 0);


{

    package TestAppDriverDBIEncode;

    use base qw(TestAppDriver);

    __PACKAGE__->authen->config(
        DRIVER => [ 'DBI',
            DBH         => $dbh,
            TABLE       => 'user',
            CONSTRAINTS => {
                'user.name'     => '__CREDENTIAL_1__',
                'user.password' => '__CREDENTIAL_2__',
                'active'        => '1'
            },
        ],
        STORE       => 'Store::Dummy',
        CREDENTIALS => [qw(username password)],
    );

}

TestAppDriverDBIEncode->run_authen_tests(
    [ 'username', 'password' ],
    [ 'user1', '123' ],
);

TestAppDriverDBIEncode->run_authen_failure_tests(
    [ 'username', 'password' ],
    [ 'user2', '123' ],
);

$dbh->do(<<"");
DROP TABLE user;


#
# ORDER BY
#
$dbh->do(<<"");
CREATE TABLE user (
    id INTEGER,
    name VARCHAR(20),
    password VARCHAR(50),
    created TIMESTAMP
)

$dbh->do(<<"");
INSERT INTO user VALUES (1, 'user1', '123', '2009-01-01');

$dbh->do(<<"");
INSERT INTO user VALUES (2, 'user2', '123', '2009-01-01');

$dbh->do(<<"");
INSERT INTO user VALUES (3, 'user1', '321', '2009-01-02');

$dbh->do(<<"");
INSERT INTO user VALUES (4, 'user2', '321', '2009-01-02');


{

    package TestAppDriverDBIEncode;

    use base qw(TestAppDriver);

    __PACKAGE__->authen->config(
        DRIVER => [ 'DBI',
            DBH         => $dbh,
            TABLE       => 'user',
            COLUMNS     => {
                'user.password' => '__CREDENTIAL_2__'
            },
            CONSTRAINTS => {
                'user.name'     => '__CREDENTIAL_1__',
            },
            ORDER_BY    => 'created DESC',
            LIMIT       => 1,
        ],
        STORE       => 'Store::Dummy',
        CREDENTIALS => [qw(username password)],
    );

}

TestAppDriverDBIEncode->run_authen_tests(
    [ 'username', 'password' ],
    [ 'user1', '321' ],
    [ 'user2', '321' ],
);

TestAppDriverDBIEncode->run_authen_failure_tests(
    [ 'username', 'password' ],
    [ 'user1', '123' ],
    [ 'user2', '123' ],
);


$dbh->do(<<"");
DROP TABLE user;



#
# ALL TOGETHER
#
$dbh->do(<<"");
CREATE TABLE user (
    id INTEGER,
    name VARCHAR(20),
    password VARCHAR(50)
)

$dbh->do(<<"");
CREATE TABLE dailycode (
    id INTEGER,
    userid INTEGER,
    date DATE DEFAULT 'CURRENT_DATE',
    code VARCHAR(20)
);

$dbh->do(<<"");
INSERT INTO user VALUES (1, 'user1', 'mQPVY1HNg8SJ2');  # crypt("123", "mQ")

$dbh->do(<<"");
INSERT INTO user VALUES (2, 'user2', 'mQPVY1HNg8SJ2');  # crypt("123", "mQ")

$dbh->do(<<"");
INSERT INTO dailycode VALUES (1, 1, 'CURRENT_DATE', '202CB962AC59075B964B07152D234B70');  # uc(md5_hex("123"))

$dbh->do(<<"");
INSERT INTO dailycode VALUES (2, 2, '2000-01-01', '202CB962AC59075B964B07152D234B70');  # uc(md5_hex("123"))


{

    package TestAppDriverDBIEncode;

    use base qw(TestAppDriver);

    __PACKAGE__->authen->config(
        DRIVER => [ 'DBI',
            DBH         => $dbh,
            TABLES      => ['user U', 'dailycode D'],
            JOIN_ON     => 'U.id = D.userid',
            COLUMNS     => {
                'crypt:U.password' => '__CREDENTIAL_2__'
            },
            CONSTRAINTS => {
                'U.name'  => '__CREDENTIAL_1__',
                'uc:MD5_hex:D.code' => '__CREDENTIAL_3__',
                'D.date'     => 'CURRENT_DATE'
            },
        ],
        STORE       => 'Store::Dummy',
        CREDENTIALS => [qw(username password dailycode)],
    );

}

TestAppDriverDBIEncode->run_authen_tests(
    [ 'username', 'password', 'dailycode' ],
    [ 'user1', '123', '123' ],
);

TestAppDriverDBIEncode->run_authen_failure_tests(
    [ 'username', 'password', 'dailycode' ],
    [ 'user1', '123', 'xxx' ],
    [ 'user1', 'xxx', '123' ],
    [ 'user2', '123', '123' ],
);

$dbh->do(<<"");
DROP TABLE user;

$dbh->do(<<"");
DROP TABLE dailycode;



$dbh->do(<<"");
CREATE TABLE user (
    name VARCHAR(20),
    password VARCHAR(50)
)

$dbh->do(<<"");
INSERT INTO user VALUES ('user1', '123');



SKIP: {
    eval "use DBI;";
    skip "DBI not available", 6 if $@;

    {

        package TestAppDriverDBIDBH;

        use base qw(TestAppDriver);

        use Test::More;
        eval "use CGI::Application::Plugin::DBH (qw/dbh dbh_config/);";
        skip "CGI::Application::Plugin::DBH not available", 6 if $@;

        sub cgiapp_init {
            my $self = shift;
            $self->dbh_config($dbh);

            $self->authen->config(
                DRIVER => [
                    'DBI',
                    TABLE       => 'user',
                    CONSTRAINTS => { 'user.name' => '__CREDENTIAL_1__', 'user.password' => '__CREDENTIAL_2__' },
                ],
                STORE => 'Store::Dummy',
                CREDENTIALS => [qw(authen_username authen_password)],
            );

        }

    }

    TestAppDriverDBIDBH->run_authen_tests(
        [ 'authen_username', 'authen_password' ],
        [ 'user1', '123' ],
    );

}

$dbh->do(<<"");
DROP TABLE user;


undef $dbh;

unlink $DBNAME if -e $DBNAME;


