#!/usr/bin/perl
use Test::More;
use lib qw(t);
eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite required for this test" if $@;

plan tests => 22;

use strict;
use warnings;

our $DBNAME = 't/sqlite.db';

unlink $DBNAME if -e $DBNAME;
my $dbh = DBI->connect( "dbi:SQLite:dbname=$DBNAME", "", "" );

$dbh->do(<<"");
CREATE TABLE account (
    id     INTEGER,
    name   VARCHAR(20)
)

$dbh->do(<<"");
INSERT INTO account VALUES (1, 'testuser');

$dbh->do(<<"");
CREATE TABLE task (
    id     INTEGER,
    userid INTEGER,
    name   VARCHAR(20)
)

$dbh->do(<<"");
INSERT INTO task VALUES (1, 1, 'task1');

$dbh->do(<<"");
INSERT INTO task VALUES (2, 1, 'task2');

$dbh->do(<<"");
CREATE TABLE ip (
    id      INTEGER,
    userid  INTEGER,
    address VARCHAR(20)
)

$dbh->do(<<"");
INSERT INTO ip VALUES (1, 1, '10.0.0.1');

$dbh->do(<<"");
INSERT INTO ip VALUES (2, 1, '10.0.0.2');


{

    package TestAppDriverDBISimple;

    use base qw(TestAppDriver);

    __PACKAGE__->authz->config(
        DRIVER => [ 'DBI',
                DBH         => $dbh,
                TABLE       => ['account A', 'task T'],
                JOIN_ON     => 'A.id = T.userid',
                USERNAME    => 'A.name',
                CONSTRAINTS => { 'T.name' => '__PARAM_1__' },
        ],
        GET_USERNAME => sub { 'testuser' },
    );

}


my $cgiapp = TestAppDriverDBISimple->new;
my $authz = $cgiapp->authz;
my ($driver) = $authz->drivers;

isa_ok($driver, 'CGI::Application::Plugin::Authorization::Driver::DBI');
can_ok($driver, 'authorize_user');

ok($driver->authorize_user('testuser', 'task1'), 'Successful authorization');
ok(! $driver->authorize_user('testuser', 'bastask'), 'Failed authorization');
ok(! $driver->authorize_user('baduser', 'task1'), 'Failed authorization');


TestAppDriverDBISimple->run_authz_success_tests( [qw(task1)], [qw(task2)] );

TestAppDriverDBISimple->run_authz_failure_tests( [qw(badtask)], [qw(badtask otherbadtask)] );

{

    package TestAppDriverDBIGroup;

    use base qw(TestAppDriver);

    __PACKAGE__->authz->config(
        DRIVER => [ 'DBI',
                DBH         => $dbh,
                TABLE       => ['account A', 'task T'],
                JOIN_ON     => 'A.id = T.userid',
                CONSTRAINTS => { 'A.name' => '__USERNAME__', 'T.name' => '__GROUP__' },
        ],
        GET_USERNAME => sub { 'testuser' },
    );

}


TestAppDriverDBIGroup->run_authz_success_tests( [qw(task1)], [qw(task2)] );

TestAppDriverDBIGroup->run_authz_failure_tests( [qw(badtask)], [qw(badtask otherbadtask)] );

{

    package TestAppDriverDBISQL;

    use base qw(TestAppDriver);

    __PACKAGE__->authz->config(
        DRIVER => [ 'DBI',
                DBH => $dbh,
                SQL => 'SELECT count(*)
                          FROM account
                          JOIN task ON (account.id = task.userid)
                         WHERE account.name = ?
                           AND task.name = ?
                       ',
        ],
        GET_USERNAME => sub { 'testuser' },
    );

}

TestAppDriverDBISQL->run_authz_success_tests( [qw(task1)], [qw(task2)] );

TestAppDriverDBISQL->run_authz_failure_tests( [qw(badtask)], [qw(otherbadtask)] );

{

    package TestAppDriverDBIComplex;

    use base qw(TestAppDriver);

    __PACKAGE__->authz->config(
        DRIVER => [ 'DBI',
                DBH         => $dbh,
                TABLE       => [qw(account task ip)],
                JOIN_ON     => 'account.id = task.userid AND account.id = ip.userid',
                USERNAME    => 'account.name',
                CONSTRAINTS => {
                    'task.name'  => '__PARAM_2__',
                    'ip.address' => '__PARAM_1__',
                },
        ],
        GET_USERNAME => sub { 'testuser' },
    );

}

TestAppDriverDBIComplex->run_authz_success_tests( [qw(10.0.0.1 task1)], [qw(10.0.0.2 task2)] );

TestAppDriverDBIComplex->run_authz_failure_tests( [qw(badip task1)], [qw(10.0.0.1 badtask)], [qw(task1)] );

