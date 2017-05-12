#!/usr/bin/perl
use Test::More;
use lib qw(t);

plan tests => 32;

use strict;
use warnings;

{

    package TestAppDriverGeneric;

    use base qw(TestAppDriver);

    __PACKAGE__->authen->config(
        DRIVER => [
            [ 'Generic', { user1 => '123' } ],
            [ 'Generic', [ [ 'user2', '234' ], [ 'user3', '345' ], ], ],
            [ 'Generic', sub { no warnings qw(uninitialized); $_[0] eq 'user4' && $_[1] eq '456' ? $_[0] : 0 } ],
        ],
        STORE => 'Store::Dummy',
    );

}


TestAppDriverGeneric->run_authen_tests(
    [ 'authen_username', 'authen_password' ],
    [ 'user1', '123' ],
    [ 'user2', '234' ],
    [ 'user3', '345' ],
    [ 'user4', '456' ],
);

TestAppDriverGeneric->run_authen_failure_tests(
    [ 'authen_username', 'authen_password' ],
    [ 'user1', 'xxx' ],
    [ 'user2', 'xxx' ],
    [ 'user3', 'xxx' ],
    [ 'user4', 'xxx' ],
);
