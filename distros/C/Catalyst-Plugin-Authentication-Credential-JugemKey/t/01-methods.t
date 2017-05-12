#!perl -T
use strict;
use warnings;

use Test::Exception;
use Test::MockObject::Extends;
use Test::MockObject;
use Test::More tests => 6;

my $m;
BEGIN {
    use_ok( $m = 'Catalyst::Plugin::Authentication::Credential::JugemKey' );
}

can_ok( $m, 'authenticate_jugemkey_url' );
can_ok( $m, 'authenticate_jugemkey_get_token' );

my $jugemkey = Test::MockObject->new;
my $auth_url = 'http://jugemkey.jp/api/auth/';
$jugemkey->mock( uri_to_login => sub { $auth_url } );

my $c = Test::MockObject::Extends->new($m);

my $user_class = Test::MockObject->new;
$user_class->fake_module('Fake::User::Class', new => sub { 1 });

my $config = {
    authentication => {
        jugemkey => {
            api_key         => 'dummy_key',
            secret          => 'dummy_secret',
            perms           => 'auth',
            jugemkey_object => $jugemkey,
            user_class      => 'Fake::User::Class',
        },
    },
};

$c->mock( config => sub {$config} );

is( $c->authenticate_jugemkey_url, $auth_url, 'returns auth_url correctly' );

my $req = Test::MockObject->new;
my $res = Test::MockObject->new;

$res->fake_module(
    'WebService::JugemKey::Auth::User',
    name  => sub {'miyashita'},
    token => sub {'dummy_token'}
);
$jugemkey->mock( get_token => sub { $res } );

my $params = {};
$req->fake_module('Catalyst::Request');
$req->mock( params => sub {$params} );
$req->mock( param => sub { $params->{$_[1]} } );
$c->mock( req                => sub {$req} );
$c->mock( default_auth_store => sub { } );
$c->mock( set_authenticated  => sub { } );
$c->mock( debug => sub { 0 } );

ok( !$c->authenticate_jugemkey_get_token, 'auth failed without frob' );

$params->{frob} = 'dummy_frob';
ok( $c->authenticate_jugemkey_get_token, 'auth succeeded with frob' );
