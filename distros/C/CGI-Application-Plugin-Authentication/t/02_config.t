#!/usr/bin/perl -T
use Test::More tests => 69;
use Test::Warn;
use Scalar::Util;
use CGI;
use strict;
use warnings;
use lib qw(t);

###############################################################################
# FAKE our own versions of these methods; newer Perls fail when we use the
# versions from Test::Exception, throwing "Bizarre copy of HASH in sassign...".
sub lives_ok(&;$) {
    my ($coderef, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $rc = eval { $coderef->() };
    ok !$@, $name;
}
sub throws_ok(&$;$) {
    my ($coderef, $expecting, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $rc = eval { $coderef->() };
    like $@, $expecting, $name;
}
# END FAKE
###############################################################################

{
    package TestAppConfig;

    use base qw(CGI::Application);
    use CGI::Application::Plugin::Authentication;

}


my %config = (
    DRIVER                => [ 'Generic', { user1 => '123', user2 => '123'} ],
    STORE                 => 'Store::Dummy',
    LOGIN_RUNMODE         => 'login',
    LOGOUT_RUNMODE        => 'logout',
    POST_LOGIN_RUNMODE    => 'start',
    CREDENTIALS           => ['authen_username', 'authen_password'],
    LOGIN_SESSION_TIMEOUT => '1h',
);
    
my $cgiapp=TestAppConfig->new;
lives_ok { $cgiapp->authen->config(%config) } 'All config parameters accepted';

is_deeply( $cgiapp->authen->credentials,[qw/authen_username authen_password/],'credentials set');
isa_ok($cgiapp->authen->drivers,'CGI::Application::Plugin::Authentication::Driver::Generic');
isa_ok($cgiapp->authen->store,'Store::Dummy');

%config = (
    DRIVER                 => [ 'HTPassword', file => 't/htpasswd' ],
    STORE                  => 'Store::Dummy',
    LOGIN_URL              => '/login.cgi',
    LOGOUT_URL             => '/',
    POST_LOGIN_URL         => '/protected/',
    CREDENTIALS            => ['authen_username', 'authen_password'],
    LOGIN_SESSION_TIMEOUT  => '1h',
);

lives_ok { TestAppConfig->new->authen->config(%config) } 'All config parameters accepted';

# test DRIVER
throws_ok { TestAppConfig->new->authen->config(DRIVER => { }) } qr/parameter DRIVER is not a string or arrayref/, 'config dies when DRIVER is passed a hashref';
lives_ok  { TestAppConfig->new->authen->config(DRIVER => 'MODULE' ) } 'config accepts single DRIVER without options';
lives_ok  { TestAppConfig->new->authen->config(DRIVER => [ 'MODULE', option => 'parameter' ] ) } 'config accepts single DRIVER with options';
lives_ok  { TestAppConfig->new->authen->config(DRIVER => [ [ 'MODULE', option => 'parameter' ], [ 'MODULE', option => 'parameter' ] ] ) } 'config accepts multiple DRIVERs';

# test STORE
throws_ok { TestAppConfig->new->authen->config(STORE => { }) } qr/parameter STORE is not a string or arrayref/, 'config dies when STORE is passed a hashref';
lives_ok  { TestAppConfig->new->authen->config(STORE => 'MODULE' ) } 'config accepts STORE without options';
lives_ok  { TestAppConfig->new->authen->config(STORE => [ 'MODULE', option => 'parameter' ] ) } 'config accepts STORE with options';

# test LOGIN_RUNMODE
throws_ok { TestAppConfig->new->authen->config(LOGIN_RUNMODE => { }) } qr/parameter LOGIN_RUNMODE is not a string/, 'config dies when LOGIN_RUNMODE is passed a hashref';
lives_ok  { TestAppConfig->new->authen->config(LOGIN_RUNMODE => 'runmode' ) } 'config accepts LOGIN_RUNMODE as a string';

# test LOGIN_URL
throws_ok { TestAppConfig->new->authen->config(LOGIN_URL => { }) } qr/parameter LOGIN_URL is not a string/, 'config dies when LOGIN_URL is passed a hashref';
lives_ok  { TestAppConfig->new->authen->config(LOGIN_URL => '/' ) } 'config accepts LOGIN_URL as a string';
warning_like  { TestAppConfig->new->authen->config(LOGIN_URL => '/', LOGIN_RUNMODE => 'runmode' ) } qr/authen config warning:  parameter LOGIN_URL ignored since we already have LOGIN_RUNMODE/, "LOGIN_URL ignored when LOGIN_RUNMODE is configured";

# test LOGOUT_RUNMODE
throws_ok { TestAppConfig->new->authen->config(LOGOUT_RUNMODE => { }) } qr/parameter LOGOUT_RUNMODE is not a string/, 'config dies when LOGOUT_RUNMODE is passed a hashref';
lives_ok  { TestAppConfig->new->authen->config(LOGOUT_RUNMODE => 'runmode' ) } 'config accepts LOGOUT_RUNMODE as a string';

# test LOGOUT_URL
throws_ok { TestAppConfig->new->authen->config(LOGOUT_URL => { }) } qr/parameter LOGOUT_URL is not a string/, 'config dies when LOGOUT_URL is passed a hashref';
lives_ok  { TestAppConfig->new->authen->config(LOGOUT_URL => '/' ) } 'config accepts LOGOUT_URL as a string';
warning_like  { TestAppConfig->new->authen->config(LOGOUT_URL => '/', LOGOUT_RUNMODE => 'runmode' ) } qr/authen config warning:  parameter LOGOUT_URL ignored since we already have LOGOUT_RUNMODE/, "LOGOUT_URL ignored when LOGOUT_RUNMODE is configured";

# test POST_LOGIN_RUNMODE
throws_ok { TestAppConfig->new->authen->config(POST_LOGIN_RUNMODE => { }) } qr/parameter POST_LOGIN_RUNMODE is not a string/, 'config dies when POST_LOGIN_RUNMODE is passed a hashref';
lives_ok  { TestAppConfig->new->authen->config(POST_LOGIN_RUNMODE => 'runmode' ) } 'config accepts POST_LOGIN_RUNMODE as a string';

# test POST_LOGIN_URL
throws_ok { TestAppConfig->new->authen->config(POST_LOGIN_URL => { }) } qr/parameter POST_LOGIN_URL is not a string/, 'config dies when POST_LOGIN_URL is passed a hashref';
lives_ok  { TestAppConfig->new->authen->config(POST_LOGIN_URL => '/' ) } 'config accepts POST_LOGIN_URL as a string';
warning_like  { TestAppConfig->new->authen->config(POST_LOGIN_URL => '/', POST_LOGIN_RUNMODE => 'runmode' ) } qr/authen config warning:  parameter POST_LOGIN_URL ignored since we already have POST_LOGIN_RUNMODE/, "POST_LOGIN_UR_URL ignored when POST_LOGIN_RUNMODE is configured";

# test POST_LOGIN_CALLBACK
throws_ok { TestAppConfig->new->authen->config(POST_LOGIN_CALLBACK => { }) } qr/parameter POST_LOGIN_CALLBACK is not a coderef/, 'config dies when POST_LOGIN_CALLBACK is passed a hashref';
throws_ok { TestAppConfig->new->authen->config(POST_LOGIN_CALLBACK => ' ') } qr/parameter POST_LOGIN_CALLBACK is not a coderef/, 'config dies when POST_LOGIN_CALLBACK is passed a string';
lives_ok  { TestAppConfig->new->authen->config(POST_LOGIN_CALLBACK => sub { } ) } 'config accepts POST_LOGIN_CALLBACK as a coderef';

# test RENDER_LOGIN
throws_ok { TestAppConfig->new->authen->config(RENDER_LOGIN => { }) } qr/parameter RENDER_LOGIN is not a coderef/, 'config dies when RENDER_LOGIN is passed a hashref';
throws_ok { TestAppConfig->new->authen->config(RENDER_LOGIN => ' ') } qr/parameter RENDER_LOGIN is not a coderef/, 'config dies when RENDER_LOGIN is passed a string';
lives_ok  { TestAppConfig->new->authen->config(RENDER_LOGIN => sub { } ) } 'config accepts RENDER_LOGIN as a coderef';

# test LOGIN_FORM
throws_ok { TestAppConfig->new->authen->config(LOGIN_FORM => ' ') } qr/parameter LOGIN_FORM is not a hashref/, 'config dies when LOGIN_FORM is passed a string';
lives_ok  { TestAppConfig->new->authen->config(LOGIN_FORM => { }) } 'config accepts LOGIN_FORM as a hashref';

# test CREDENTIALS
throws_ok { TestAppConfig->new->authen->config(CREDENTIALS => { }) } qr/parameter CREDENTIALS is not a string/, 'config dies when CREDENTIALS is passed a hashref';
lives_ok  { TestAppConfig->new->authen->config(CREDENTIALS => 'authen_username' ) } 'config accepts CREDENTIALS as a string';
lives_ok  { TestAppConfig->new->authen->config(CREDENTIALS => ['authen_username', 'authen_password'] ) } 'config accepts CREDENTIALS as an arrayref';

# test LOGIN_SESSION_TIMEOUT
lives_ok  { TestAppConfig->new->authen->config(LOGIN_SESSION_TIMEOUT => '5h' ) } 'config accepts LOGIN_SESSION_TIMEOUT as a string';
lives_ok  { TestAppConfig->new->authen->config(LOGIN_SESSION_TIMEOUT => { IDLE_FOR => 1 } ) } 'config accepts LOGIN_SESSION_TIMEOUT with IDLE_FOR option';
lives_ok  { TestAppConfig->new->authen->config(LOGIN_SESSION_TIMEOUT => { EVERY => 1 } ) } 'config accepts LOGIN_SESSION_TIMEOUT with EVERY option';
lives_ok  { TestAppConfig->new->authen->config(LOGIN_SESSION_TIMEOUT => { CUSTOM => sub { 1 } } ) } 'config accepts LOGIN_SESSION_TIMEOUT with CUSTOM option';
lives_ok  { TestAppConfig->new->authen->config(LOGIN_SESSION_TIMEOUT => { IDLE_FOR => 1, EVERY => 1, CUSTOM => sub { 1 } } ) } 'config accepts LOGIN_SESSION_TIMEOUT as a hashref';

throws_ok { TestAppConfig->new->authen->config(LOGIN_SESSION_TIMEOUT => [ ]) } qr/parameter LOGIN_SESSION_TIMEOUT is not a string or a hashref/, 'config dies when LOGIN_SESSION_TIMEOUT is passed a hashref';
throws_ok { TestAppConfig->new->authen->config(LOGIN_SESSION_TIMEOUT => '5dodgy' ) } qr/parameter LOGIN_SESSION_TIMEOUT is not a valid time string/, 'config dies when LOGIN_SESSION_TIMEOUT recieves an unparsable string';
throws_ok { TestAppConfig->new->authen->config(LOGIN_SESSION_TIMEOUT => { IDLE_FOR => '5dodgy' } ) } qr/IDLE_FOR option to LOGIN_SESSION_TIMEOUT is not a valid time string/, 'config dies when LOGIN_SESSION_TIMEOUT IDLE_FOR recieves an unparsable string';
throws_ok { TestAppConfig->new->authen->config(LOGIN_SESSION_TIMEOUT => { EVERY => '5dodgy' } ) } qr/EVERY option to LOGIN_SESSION_TIMEOUT is not a valid time string/, 'config dies when LOGIN_SESSION_TIMEOUT EVERY recieves an unparsable string';
throws_ok { TestAppConfig->new->authen->config(LOGIN_SESSION_TIMEOUT => { CUSTOM => 'notasub' } ) } qr/CUSTOM option to LOGIN_SESSION_TIMEOUT must be a code reference/, 'config dies when LOGIN_SESSION_TIMEOUT CUSTOM receives something other than a coderef';
throws_ok { TestAppConfig->new->authen->config(LOGIN_SESSION_TIMEOUT => { BADOPTION => 1 } ) } qr/Invalid option\(s\) \(BADOPTION\) passed to LOGIN_SESSION_TIMEOUT/, 'config dies when LOGIN_SESSION_TIMEOUT recieves an unparsable string';

# authen->config as a class method
lives_ok { TestAppConfig->authen->config(%config) } 'config can be called as a class method';

# authen->config as a class method with hashref
lives_ok { TestAppConfig->authen->config(\%config) } 'config can be called with a hashref or hash';

# authen->config with no parameters
lives_ok { TestAppConfig->authen->config() } 'current configuration returned';

# authen->config dies when passed an invalid parameter
throws_ok { TestAppConfig->new->authen->config(BAD_PARAM => 'foobar' ) } qr/Invalid option\(s\)/, 'config dies when passed an invalid parameter';

# authen->config dies when it is called after the plugin has been initialized
my $app = TestAppConfig->new;
my $authen = $app->authen;
$authen->config( \%config );
$authen->initialize;
throws_ok { $authen->config( \%config ) } qr/Calling config after the Authentication object has already been initialized/, 'config dies when called after initialization with new configuration info';


# test _time_to_seconds
is(CGI::Application::Plugin::Authentication::_time_to_seconds('10'), 10, "_time_to_seconds works with number only");
is(CGI::Application::Plugin::Authentication::_time_to_seconds('10s'), 10, "_time_to_seconds works with seconds");
is(CGI::Application::Plugin::Authentication::_time_to_seconds('10m'), 600, "_time_to_seconds works with minutes");
is(CGI::Application::Plugin::Authentication::_time_to_seconds('10h'), 36000, "_time_to_seconds works with hours");
is(CGI::Application::Plugin::Authentication::_time_to_seconds('10d'), 864000, "_time_to_seconds works with days");
is(CGI::Application::Plugin::Authentication::_time_to_seconds('10w'), 6048000, "_time_to_seconds works with weeks");
is(CGI::Application::Plugin::Authentication::_time_to_seconds('10M'), 25920000, "_time_to_seconds works with months");
is(CGI::Application::Plugin::Authentication::_time_to_seconds('10y'), 315360000, "_time_to_seconds works with years");
is(CGI::Application::Plugin::Authentication::_time_to_seconds('.5m'), 30, "_time_to_seconds works with decimal values");
is(CGI::Application::Plugin::Authentication::_time_to_seconds('0.5m'), 30, "_time_to_seconds works with decimal values");
is(CGI::Application::Plugin::Authentication::_time_to_seconds('1.5m'), 90, "_time_to_seconds works with decimal values");
is(CGI::Application::Plugin::Authentication::_time_to_seconds('1.m'), 60, "_time_to_seconds works with decimal values");
is(CGI::Application::Plugin::Authentication::_time_to_seconds('1.0m'), 60, "_time_to_seconds works with decimal values");
is(CGI::Application::Plugin::Authentication::_time_to_seconds((1 / 7).'m'), 8, "_time_to_seconds works with decimal value that wouldn't result in an integer offset");
is(CGI::Application::Plugin::Authentication::_time_to_seconds('.5'), undef, "_time_to_seconds fails with decimal values and no modifier");


TODO: {
local $TODO = "TestAppConfig->new->authen->config not finished";


}

