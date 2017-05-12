#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;
use Test::Exception;
use lib qw(t);
eval "use Apache::Htpasswd 1.8;";
plan skip_all => "Apache::Htpasswd >= 1.8 required for this test" if $@;

plan tests => 31;

use strict;
use warnings;

our $HTPASSWD  = 't/htpasswd';
our $HTPASSWD2 = 't/htpasswd2';

{

    package TestAppDriverHTPasswd;

    use base qw(TestAppDriver);

    __PACKAGE__->authen->config(
        DRIVER => [ 'HTPasswd', $HTPASSWD, $HTPASSWD2 ],
        STORE => 'Store::Dummy',
    );

}

TestAppDriverHTPasswd->run_authen_tests(
    [ 'authen_username', 'authen_password' ],
    [ 'user1', '123' ],
    [ 'user2', '123' ],
    [ 'user3', '123' ],
    [ 'user4', '123' ],
    [ 'user5', '123' ],
);

# Test bad config
{

    package TestAppDriverHTPasswd2;

    use base qw(TestAppDriver);

    __PACKAGE__->authen->config(
        DRIVER => [ 'HTPasswd' ],
        STORE => 'Store::Dummy',
    );

}

throws_ok {TestAppDriverHTPasswd2->run_authen_tests(
    [ 'authen_username', 'authen_password' ],
    [ 'user1', '123' ],
);} qr/Error executing class callback in prerun stage: The HTPasswd driver requires at least one htpasswd file/,  'no htpasswd files';
