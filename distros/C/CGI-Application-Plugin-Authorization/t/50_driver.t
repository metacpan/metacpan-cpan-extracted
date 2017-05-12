#!/usr/bin/perl
use Test::More;
use Test::Exception;
use lib qw(t);

plan tests => 8;

use strict;
use warnings;

{

    package TestAppDriverBasic;

    use base qw(TestAppDriver);

    __PACKAGE__->authz->config(
        DRIVER => [
            [ 'Dummy', PARAM1 => 'param1', PARAM2 => 'param2' ],
            [ 'Generic', sub { 1 } ],
        ],
    );

}

my $cgiapp = TestAppDriverBasic->new;

my @drivers = $cgiapp->authz->drivers;

isa_ok($drivers[0], 'CGI::Application::Plugin::Authorization::Driver::Dummy');
isa_ok($drivers[1], 'CGI::Application::Plugin::Authorization::Driver::Generic');

is($drivers[0]->find_option('PARAM2'), 'param2', 'find_option returns correct parameter');
is($drivers[0]->find_option('PARAM1'), 'param1', 'find_option returns correct parameter');
is($drivers[0]->find_option('PARAM'), undef, 'find_option returns undef when parameter not found');


throws_ok { CGI::Application::Plugin::Authorization::Driver->authorize_user } qr/authorize_user must be implemented in the subclass/, "authorize_user dies unless overriden in a subclass";



{
    package TestAppDriverInvalid;

    use base qw(TestAppDriver);

    __PACKAGE__->authz->config(
        DRIVER => [
            [ 'Invalid' ],
        ],
    );

}

throws_ok { TestAppDriverInvalid->new->authz->authorize('testgroup') } qr/Could not create new Invalid object/, "die with invalid driver";

{
    package TestAppDriverNonExistant;

    use base qw(TestAppDriver);

    __PACKAGE__->authz->config(
        DRIVER => [
            [ 'NonExistant::Driver' ],
        ],
    );

}

throws_ok { TestAppDriverNonExistant->new->authz->authorize('testgroup') } qr/Driver NonExistant::Driver can not be found/, "die with invalid driver";
