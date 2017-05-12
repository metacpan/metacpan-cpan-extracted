#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 27;
use Test::Exception;
use Test::MockObject;

BEGIN {
    use_ok('Catalyst::Authentication::Credential::HTTP::Proxy');
}

my $mock_c = Test::MockObject->new;
$mock_c->mock('debug' => sub { 0 });
my ($authenticated_user, $authenticated);
$mock_c->mock('set_authenticated' => sub { $authenticated_user = $_[1]; $authenticated++; });

my ($auth_info, $user);
my $mock_realm = Test::MockObject->new;
$mock_realm->mock('find_user' => sub { $auth_info = $_[1]; return $user });

throws_ok {
    Catalyst::Authentication::Credential::HTTP::Proxy->new({}, $mock_c, $mock_realm);
} qr/Catalyst::Authentication::Credential::HTTP::Proxy/, 'No config throws';

lives_ok { 
    Catalyst::Authentication::Credential::HTTP::Proxy->new(
        {url => 'http://some.proxy:8080'},
        $mock_c, $mock_realm,
    );
} 'Normal (with url) ok';

throws_ok {
    Catalyst::Authentication::Credential::HTTP::Proxy->new(
        {url => 'http://some.proxy:8080',
        type => 'foobar'},
        $mock_c, $mock_realm,
    );
} qr/Catalyst::Authentication::Credential::HTTP::Proxy/, 'Asking for unknown type throws';

my $log = Test::MockObject->new;
$log->mock('info' => sub {});
$log->mock('debug' => sub {});
my $req = Test::MockObject->new;
my $req_headers = HTTP::Headers->new;
my $res = Test::MockObject->new;
$req->set_always( headers => $req_headers );
my $status;
$res->mock(status => sub { $status = $_[1] });
my $content_type;
$res->mock(content_type => sub { $content_type = $_[1] });
my $body;
my $headers;
$res->mock(body => sub { $body = $_[1] });
my $res_headers = HTTP::Headers->new;
$res->set_always( headers => $res_headers );
$mock_c->set_always( debug => 0 );
$mock_c->set_always( config => {} );
$mock_c->set_always( req => $req );
$mock_c->set_always( res => $res );
$mock_c->set_always( request => $req );
$mock_c->set_always( response => $res );
$mock_c->set_always( log => $log );

$mock_realm->set_always(name => 'myrealm');

my $cred = Catalyst::Authentication::Credential::HTTP::Proxy->new(
    {url => 'http://some.proxy:8080',
    type => 'basic'},
    $mock_c, $mock_realm,
);

ok(!$cred->authenticate_basic($mock_c, $mock_realm, {}), '_authenticate_basic returns false with no auth headers');
throws_ok {
    $cred->authenticate($mock_c, $mock_realm, {});
} qr/^$Catalyst::DETACH$/, '$cred->authenticate calls detach';

like( ($res_headers->header('WWW-Authenticate'))[0], qr/^Basic/, "WWW-Authenticate header set: basic");
like( ($res_headers->header('WWW-Authenticate'))[0], qr/realm="myrealm"/, "WWW-Authenticate header set: basic realm");

$res_headers->clear;

$req_headers->authorization_basic( qw/Mufasa password/ );
my ($auth_ua, $auth_res, $auth_url);
{
    no warnings qw/redefine once/;
    *Catalyst::Authentication::Credential::HTTP::Proxy::User::get = sub { $auth_ua = shift; $auth_url = shift; $auth_res };
}
$auth_res = HTTP::Response->new;
$auth_res->code(500);
$auth_res->message('FAIL');

ok(!$cred->authenticate_basic($mock_c, $mock_realm, {}), '_authenticate_basic returns false with auth response !success');
is_deeply([$auth_ua->get_basic_credentials], [qw/Mufasa password/], 'Basic auth in useragent is Mufasa/password');
is($auth_url, 'http://some.proxy:8080', 'get http://some.proxy:8080');
throws_ok {
    $cred->authenticate($mock_c, $mock_realm, {});
} qr/^$Catalyst::DETACH$/, '$cred->authenticate calls detach with auth response !success';

like( ($res_headers->header('WWW-Authenticate'))[0], qr/^Basic/, "WWW-Authenticate header set: basic");
like( ($res_headers->header('WWW-Authenticate'))[0], qr/realm="myrealm"/, "WWW-Authenticate header set: basic realm");

$res_headers->clear;
$auth_res->code(200);
($auth_url, $auth_ua) = (undef, undef);

ok(!$cred->authenticate_basic($mock_c, $mock_realm, {}), '_authenticate_basic returns false with auth response success but no user from realm');
is_deeply([$auth_ua->get_basic_credentials], [qw/Mufasa password/], 'Basic auth in useragent is Mufasa/password');
is($auth_url, 'http://some.proxy:8080', 'get http://some.proxy:8080');
is_deeply($auth_info, { username => 'Mufasa'}, '$realm->find_user({ username => "Mufasa" })');
ok(!$authenticated, 'Not set_authenticated');
throws_ok {
    $cred->authenticate($mock_c, $mock_realm, {});
} qr/^$Catalyst::DETACH$/, '$cred->authenticate calls detach with auth response !success';

($auth_url, $auth_ua) = (undef, undef);
$res_headers->clear;
$user = Test::MockObject->new;

ok($cred->authenticate_basic($mock_c, $mock_realm, {}), '_authenticate_basic returns true with auth response success and user from realm');
is_deeply([$auth_ua->get_basic_credentials], [qw/Mufasa password/], 'Basic auth in useragent is Mufasa/password');
is_deeply($auth_info, { username => 'Mufasa'}, '$realm->find_user({ username => "Mufasa" })');
ok($authenticated, 'Called set_authenticated');
is("$authenticated_user", "$user", 'Called set_authenticated with user object');
lives_ok {
    $cred->authenticate($mock_c, $mock_realm, {});
} '$cred->authenticate does not detach';
ok(!$res_headers->header('WWW-Authenticate'), 'No authenticate header on successful auth');
