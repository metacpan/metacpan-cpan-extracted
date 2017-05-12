#!/usr/bin/perl
use Test::More;
use Test::Exception;
use lib qw(t);

plan tests => 6;

use strict;
use warnings;

{

    package TestAppDriverGeneric;

    use base qw(TestAppDriver);

    my %groupmap = ( testuser => 'testgroup', );

    __PACKAGE__->authz->config(
        DRIVER       => [ 'Generic', sub { return $groupmap{ $_[0] } eq $_[1] ? 1 : 0 } ],
        GET_USERNAME => sub { 'testuser' },
    );

}

TestAppDriverGeneric->run_authz_success_tests( [qw(testgroup)], [qw(othertestgroup testgroup)] );

TestAppDriverGeneric->run_authz_failure_tests( [qw(badgroup)], [qw(badgroup otherbadgroup)] );

{

    package TestAppDriverGenericBadSub;

    use base qw(TestAppDriver);

    my %groupmap = ( testuser => 'testgroup', );

    __PACKAGE__->authz->config(
        DRIVER       => [ 'Generic' ],
        GET_USERNAME => sub { 'testuser' },
    );

}

throws_ok { TestAppDriverGenericBadSub->authz->authorize('testgroup') } qr/The Generic driver requires a subroutine reference as its only option/, "Generic driver dies with non CODE driver option";

{

    package TestAppDriverGenericNoSub;

    use base qw(TestAppDriver);

    my %groupmap = ( testuser => 'testgroup', );

    __PACKAGE__->authz->config(
        DRIVER       => [ 'Generic', 'BADVALUE' ],
        GET_USERNAME => sub { 'testuser' },
    );

}

throws_ok { TestAppDriverGenericNoSub->authz->authorize('testgroup') } qr/The Generic driver requires a subroutine reference as its only option/, "Generic driver dies with non CODE driver option";

