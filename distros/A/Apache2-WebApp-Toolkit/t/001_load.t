# -*- perl -*-

use strict;
use warnings FATAL => 'all';

# t/001_load.t - check module loading

use Apache::Test qw( :withtestmore );
use Test::More;

BEGIN {
    use_ok('Apache2::WebApp');
    use_ok('Apache2::WebApp::AppConfig');
    use_ok('Apache2::WebApp::Helper');
    use_ok('Apache2::WebApp::Helper::Class');
    use_ok('Apache2::WebApp::Helper::Extra');
    use_ok('Apache2::WebApp::Helper::Kickstart');
    use_ok('Apache2::WebApp::Helper::Project');
    use_ok('Apache2::WebApp::Plugin');
    use_ok('Apache2::WebApp::Stash');
    use_ok('Apache2::WebApp::Template');
}

ok 1;

my $obj1 = new Apache2::WebApp;
my $obj2 = new Apache2::WebApp::AppConfig;
my $obj3 = new Apache2::WebApp::Helper;
my $obj4 = new Apache2::WebApp::Helper::Class;
my $obj5 = new Apache2::WebApp::Helper::Extra;
my $obj6 = new Apache2::WebApp::Helper::Kickstart;
my $obj7 = new Apache2::WebApp::Helper::Project;
my $obj8 = new Apache2::WebApp::Plugin;
my $obj9 = new Apache2::WebApp::Stash;
my $obj0 = new Apache2::WebApp::Template;

isa_ok($obj1, 'Apache2::WebApp');
isa_ok($obj2, 'Apache2::WebApp::AppConfig');
isa_ok($obj3, 'Apache2::WebApp::Helper');
isa_ok($obj4, 'Apache2::WebApp::Helper::Class');
isa_ok($obj5, 'Apache2::WebApp::Helper::Extra');
isa_ok($obj6, 'Apache2::WebApp::Helper::Kickstart');
isa_ok($obj7, 'Apache2::WebApp::Helper::Project');
isa_ok($obj8, 'Apache2::WebApp::Plugin');
isa_ok($obj9, 'Apache2::WebApp::Stash');
isa_ok($obj0, 'Template');

done_testing();
