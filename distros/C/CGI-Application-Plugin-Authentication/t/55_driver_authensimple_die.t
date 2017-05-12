#!/usr/bin/perl

use Test::More;
use Test::Exception;
use Test::Warn;
use Test::MockObject;
use lib qw(t);

BEGIN {
    eval {require Params::Validate};
    if ($@) {
	my $msg = "Authen::Simple depends on Params::Validate, hence this test also";
	plan skip_all => $msg;
    }
}

my $authensimple = Test::MockObject->new;
$authensimple->fake_module('Authen::Simple::Adapter', new=>sub{return undef},options=>sub{1});

plan tests => 1;

use strict;
use warnings;

{
    package TestAppDriverAuthenSimple;

    use base qw(TestAppDriver);

    __PACKAGE__->authen->config(
        DRIVER => [ 'Authen::Simple::Dummy', testuser => 'user1', testpass => '123' ],
        STORE  => 'Store::Dummy',
    );

}

throws_ok {
    TestAppDriverAuthenSimple->run_authen_tests(
        [ 'authen_username', 'authen_password' ],
        [ 'user1', '123' ],
    );
} qr/Error executing class callback in prerun stage: Failed to create Authen::Simple::Dummy instance/, 'throws error correctly';


