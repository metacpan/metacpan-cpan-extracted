#!/usr/bin/perl
use Test::More tests => 18;
use Test::Exception;
use Scalar::Util;

BEGIN { require_ok('CGI::Application::Plugin::Authorization') };

use lib './t';
use strict;
use warnings;

{
    package TestAppBasic;

    use base qw(CGI::Application);
    use CGI::Application::Plugin::Authorization;
}

{

    package TestAppBasicNOTCA;

    use Test::More;

    sub new {
        return bless {}, 'TestAppBasicNOTCA';
    }

    SKIP: {
        eval "use Test::Warn";
        skip "Test::Warn required for this test", 1 if $@;

        #### Disable since Sub::Uplevel 0.09 spits out useless warnings under perl 5.8.8
        #warning_like( sub { CGI::Application::Plugin::Authorization->import() },
        #  qr/Calling package is not a CGI::Application module so not setting up the prerun hook/,
        #  "warning when the plugin is used in a non-CGIApp module");
    };

    {
        local $SIG{__WARN__} = sub {}; # supress all warnings for the next line
        CGI::Application::Plugin::Authorization->import();
    };

    Test::Exception::throws_ok(
        sub { TestAppBasicNOTCA->new->authz },
        qr/CGI::Application::Plugin::Authorization->instance must be called with a CGI::Application object/,
        "instance dies when called passed non CGI::App module"
    );

}

{
    my $authz = TestAppBasic->authz;
    isa_ok($authz, "CGI::Application::Plugin::Authorization");

    my $authz2 = TestAppBasic->authz;
    isa_ok($authz2, "CGI::Application::Plugin::Authorization");
    ok($authz ne $authz2, "calling ->authz as a class method multiple times gives different objects");

    my $authz3 = TestAppBasic->authz('named');
    isa_ok($authz3, "CGI::Application::Plugin::Authorization");
    like($authz3->{name}, qr/named/, "returned object has a unique name");

    my $authz4 = TestAppBasic->authz('named');
    isa_ok($authz4, "CGI::Application::Plugin::Authorization");
    ok($authz3 ne $authz4, "calling ->authz('named') as a class method multiple times gives different objects");
}



my $t1_obj = TestAppBasic->new();
my $authz = $t1_obj->authz;
my $authz_again = $t1_obj->authz;
my $authz_named = $t1_obj->authz('named');

isa_ok($authz, 'CGI::Application::Plugin::Authorization');

ok(Scalar::Util::refaddr($authz) != Scalar::Util::refaddr($authz_named), "Named objects have different address");
ok(Scalar::Util::refaddr($t1_obj->authz) != Scalar::Util::refaddr($authz_named), "Caching named objects works correctly");


my $t2_obj = TestAppBasic->new();
my $authz2 = $t2_obj->authz;

isa_ok($authz2, 'CGI::Application::Plugin::Authorization');

ok(Scalar::Util::refaddr($authz) != Scalar::Util::refaddr($authz2), "Objects have different address");
is(Scalar::Util::refaddr($authz), Scalar::Util::refaddr($authz_again), "Objects have same address");


throws_ok(sub { CGI::Application::Plugin::Authorization->instance }, qr/CGI::Application::Plugin::Authorization->instance must be called with a CGI::Application object/, "instance dies when called incorrectly");


# Check default Dummy driver
isa_ok($authz->drivers, 'CGI::Application::Plugin::Authorization::Driver::Dummy');

ok($authz->authorize, 'Dummy authorizes everything');

