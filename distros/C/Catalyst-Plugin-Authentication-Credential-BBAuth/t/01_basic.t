use strict;
use Test::MockObject;
use Test::MockObject::Extends;
use Test::More tests => 6;

my $m;
BEGIN {
    use_ok($m = 'Catalyst::Plugin::Authentication::Credential::BBAuth');
}

can_ok($m, 'authenticate_bbauth');
can_ok($m, 'authenticate_bbauth_url');

my $bbauth   = Test::MockObject->new;
my $auth_url = 'https://api.login.yahoo.com/WSLogin/V1/wslogin';
$bbauth->mock(auth_url => sub { $auth_url });
$bbauth->mock(userhash => sub { 'my_userhash' });

my $c = Test::MockObject::Extends->new($m);

my $user_class = Test::MockObject->new;
$user_class->fake_module('Fake::User::Class', new => sub {});

my $config = {
    authentication => {
        bbauth => {
            appid      => 'my_appid',
            secret     => 'my_secret',
            user_class => 'Fake::User::Class',
            bbauth_object => $bbauth,
        },
    },
};
$c->mock(config => sub { $config });

is($c->authenticate_bbauth_url, $auth_url, 'returns auth_url correctly');

my $req = Test::MockObject->new;

my $params = {};
$req->fake_module('Catalyst::Request');
$req->mock(params => sub { $params });
$c->mock(req => sub { $req });
$c->mock(debug => sub { 0 });
$c->mock(default_auth_store => sub { } );
$c->mock(set_authenticated  => sub { } );

$bbauth->mock(validate_sig => sub { 1 });

ok(!$c->authenticate_bbauth, 'auth failes without token parameter');

$params->{token} = 'my_token';
ok($c->authenticate_bbauth, 'auth successful with token');

