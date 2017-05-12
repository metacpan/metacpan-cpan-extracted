#!/usr/bin/perl -T
use Test::More tests => 9;
use Test::Exception;
use Scalar::Util;

BEGIN { require_ok('CGI::Application::Plugin::Authentication') };

use lib './t';
use strict;
use warnings;

{
    package TestAppBasic;

    use base qw(CGI::Application);
    use CGI::Application::Plugin::Authentication;
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

        warning_like( sub { CGI::Application::Plugin::Authentication->import() },
          qr/Calling package is not a CGI::Application module so not setting up the prerun hook/,
          "warning when the plugin is used in a non-CGIApp module");
    };

    {
        local $SIG{__WARN__} = sub {}; # supress all warnings for the next line
        CGI::Application::Plugin::Authentication->import();
    };

    Test::Exception::throws_ok(
        sub { TestAppBasicNOTCA->new->authen },
        qr/CGI::Application::Plugin::Authentication->instance must be called with a CGI::Application object/,
        "instance dies when called passed non CGI::App module"
    );

}

is(TestAppBasic->authen, "CGI::Application::Plugin::Authentication", "->authen called as a class method works");



my $t1_obj = TestAppBasic->new();
my $authen = $t1_obj->authen;
my $authen_again = $t1_obj->authen;

isa_ok($authen, 'CGI::Application::Plugin::Authentication');


my $t2_obj = TestAppBasic->new();
my $authen2 = $t2_obj->authen;

isa_ok($authen2, 'CGI::Application::Plugin::Authentication');

ok(Scalar::Util::refaddr($authen) != Scalar::Util::refaddr($authen2), "Objects have same different address");
is(Scalar::Util::refaddr($authen), Scalar::Util::refaddr($authen_again), "Objects have same address");


throws_ok(sub { CGI::Application::Plugin::Authentication->instance }, qr/CGI::Application::Plugin::Authentication->instance must be called with a CGI::Application object/, "instance dies when called incorrectly");



