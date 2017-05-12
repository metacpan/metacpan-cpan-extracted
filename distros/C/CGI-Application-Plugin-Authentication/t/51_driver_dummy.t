#!/usr/bin/perl
use Test::More;
use lib qw(t);

plan tests => 8;

use strict;
use warnings;

{

    package TestAppDriverGeneric;

    use base qw(TestAppDriver);

    __PACKAGE__->authen->config(
        DRIVER => 'Dummy',
        STORE => 'Store::Dummy',
    );

}


TestAppDriverGeneric->run_authen_success_tests(
    [ 'authen_username', 'authen_password' ],
    [ 'user1', '123' ],
    [ 'user2', '234' ],
    [ 'user3', '' ],
    [ 'user4' ],
);

