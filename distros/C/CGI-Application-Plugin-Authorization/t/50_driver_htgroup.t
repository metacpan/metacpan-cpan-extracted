#!/usr/bin/perl
use Test::More;
use Test::Exception;
use lib qw(t);

eval "use Apache::Htgroup";
plan skip_all => "Apache::Htgroup required for these tests" if $@;

plan tests => 6;

use strict;
use warnings;

{

    package TestAppDriverHTGroup;

    use base qw(TestAppDriver);

    __PACKAGE__->authz->config(
        DRIVER       => [ 'HTGroup', 't/htgroup', 't/htgroup2' ],
        GET_USERNAME => sub { 'testuser' },
    );

}

TestAppDriverHTGroup->run_authz_success_tests( [qw(testgroup)], [qw(othertestgroup testgroup)], [qw(testgroup2)] );

TestAppDriverHTGroup->run_authz_failure_tests( [qw(badgroup)], [qw(badgroup otherbadgroup)] );

{

    package TestAppDriverHTGroupNoFile;

    use base qw(TestAppDriver);

    __PACKAGE__->authz->config(
        DRIVER       => [ 'HTGroup' ],
        GET_USERNAME => sub { 'testuser' },
    );

}

throws_ok { TestAppDriverHTGroupNoFile->authz->authorize('testgroup') } qr/The HTGroup driver requires at least one htgroup file/, "HTGroup driver dies with no htgroup filename";

