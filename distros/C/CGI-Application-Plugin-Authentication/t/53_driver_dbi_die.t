#!/usr/bin/perl

BEGIN {push @ARGV, '--dbtest';}

use Test::More;
use Test::Exception;
use Test::Warn;
use lib qw(t);

my $dbh;
    use Test::MockObject;
    $dbh = Test::MockObject->new;
    $dbh->set_isa('DBI');
    $dbh->fake_module('DBI');
    $dbh->mock('prepare_cached', sub {return $dbh;});
    $dbh->set_false('execute');
    $dbh->set_always('errstr', 'Mock error');

plan tests => 1;

use strict;
use warnings;


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
throws_ok {$cgiapp->run;} qr/Error executing class callback in prerun stage: Mock error/, 'throws error correctly';

undef $dbh;






