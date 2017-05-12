#!/usr/bin/perl
use Test::More tests => 18;
use Test::Exception;
use Test::Warn;
use Scalar::Util;
use CGI;
use strict;
use warnings;
use lib qw(t);

{
    package TestAppConfig;

    use base qw(CGI::Application);
    use CGI::Application::Plugin::Authorization;

}


my %config = (
    DRIVER            => [ 'Generic', sub { 1 } ],
    FORBIDDEN_RUNMODE => 'forbidden',
    GET_USERNAME      => sub {'cees'},
);
    
my $cgiapp = TestAppConfig->new;
lives_ok { $cgiapp->authz->config(%config) } 'All config parameters accepted';
isa_ok($cgiapp->authz->drivers,'CGI::Application::Plugin::Authorization::Driver::Generic');

%config = (
    DRIVER        => [ 'Generic', sub { 1 } ],
    FORBIDDEN_URL => '/forbidden.html',
);

lives_ok { TestAppConfig->new->authz->config(%config) } 'All config parameters accepted';

# test DRIVER
throws_ok { TestAppConfig->new->authz->config(DRIVER => { }) } qr/parameter DRIVER is not a string or arrayref/, 'config dies when DRIVER is passed a hashref';
lives_ok  { TestAppConfig->new->authz->config(DRIVER => 'MODULE' ) } 'config accepts single DRIVER without options';
lives_ok  { TestAppConfig->new->authz->config(DRIVER => [ 'MODULE', option => 'parameter' ] ) } 'config accepts single DRIVER with options';
lives_ok  { TestAppConfig->new->authz->config(DRIVER => [ [ 'MODULE', option => 'parameter' ], [ 'MODULE', option => 'parameter' ] ] ) } 'config accepts multiple DRIVERs';

# test FORBIDDEN_RUNMODE
throws_ok { TestAppConfig->new->authz->config(FORBIDDEN_RUNMODE => { }) } qr/parameter FORBIDDEN_RUNMODE is not a string/, 'config dies when FORBIDDEN_RUNMODE is passed a hashref';
lives_ok  { TestAppConfig->new->authz->config(FORBIDDEN_RUNMODE => 'runmode' ) } 'config accepts FORBIDDEN_RUNMODE as a string';

# test FORBIDDEN_URL
throws_ok { TestAppConfig->new->authz->config(FORBIDDEN_URL => { }) } qr/parameter FORBIDDEN_URL is not a string/, 'config dies when FORBIDDEN_URL is passed a hashref';
lives_ok  { TestAppConfig->new->authz->config(FORBIDDEN_URL => '/' ) } 'config accepts FORBIDDEN_URL as a string';
#### Disable since Sub::Uplevel 0.09 spits out useless warnings under perl 5.8.8
#warning_like  { TestAppConfig->new->authz->config(FORBIDDEN_URL => '/forbidden.html', FORBIDDEN_RUNMODE => 'forbidden' ) } qr/authz config warning:  parameter FORBIDDEN_URL ignored since we already have FORBIDDEN_RUNMODE/, "FORBIDDEN_URL ignored when FORBIDDEN_RUNMODE is configured";

# test GET_USERNAME
throws_ok { TestAppConfig->new->authz->config(GET_USERNAME => { }) } qr/parameter GET_USERNAME is not a CODE reference/, 'config dies when GET_USERNAME is passed a hashref';
lives_ok  { TestAppConfig->new->authz->config(GET_USERNAME => sub { 1 } ) } 'config accepts GET_USERNAME as a CODE reference';


# authz->config as a class method
lives_ok { TestAppConfig->authz->config(%config) } 'config can be called as a class method';

# authz->config as a class method with hashref
lives_ok { TestAppConfig->authz->config(\%config) } 'config can be called with a hashref or hash';

# authz->config with no parameters
lives_ok { TestAppConfig->authz->config() } 'current configuration returned';

# authz->config dies when passed an invalid parameter
throws_ok { TestAppConfig->new->authz->config(BAD_PARAM => 'foobar' ) } qr/Invalid option\(s\)/, 'config dies when passed an invalid parameter';

# authz->config dies when it is called after the plugin has been initialized
my $app = TestAppConfig->new;
my $authz = $app->authz;
$authz->config( \%config );
$authz->drivers;
throws_ok { $authz->config( \%config ) } qr/Calling config after the Authorization object has already been created/, 'config dies when called after initialization with new configuration info';



TODO: {
local $TODO = "TestAppConfig->new->authz->config not finished";


}

