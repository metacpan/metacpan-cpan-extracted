#!/usr/bin/perl
use Test::More;
use Test::Exception;
use lib qw(t);

plan tests => 4;

use strict;
use warnings;

{

    package TestAppDriverSimpleGroup;

    use base qw(TestAppDriver);

    __PACKAGE__->authz->config(
        DRIVER       => 'SimpleGroup',
        GET_USERNAME => sub { return $_[0]->cgiapp->param('group') },
    );

    sub cgiapp_init {
        my $self = shift;
        $self->param('group' => 'testgroup');
    }

}

TestAppDriverSimpleGroup->run_authz_success_tests( [qw(testgroup)], [qw(othertestgroup testgroup)] );

TestAppDriverSimpleGroup->run_authz_failure_tests( [qw(badgroup)], [qw(badgroup otherbadgroup)] );

