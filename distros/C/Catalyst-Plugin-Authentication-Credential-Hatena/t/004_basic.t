#!/usr/bin/perl

use strict;
use warnings;

use Test::Exception;
use Test::MockObject::Extends;
use Test::MockObject;
use Test::More tests => 6;

use HTTP::Response;

my $m;
BEGIN {
    use_ok( $m = 'Catalyst::Plugin::Authentication::Credential::Hatena' );
}

can_ok( $m, 'authenticate_hatena' );
can_ok( $m, 'authenticate_hatena_url' );

my $hatena   = Test::MockObject->new;
my $auth_url = 'http://auth.hatena.ne.jp/auth';
$hatena->mock( uri_to_login => sub {$auth_url} );

my $c = Test::MockObject::Extends->new($m);

my $user_class = Test::MockObject->new;
$user_class->fake_module('Fake::User::Class', new => sub {});

my $config = {
    authentication => {
        hatena => {
            key        => 'my_key',
            secret     => 'my_secret',
            perms      => 'write',
            user_class => 'Fake::User::Class',

            hatena_object => $hatena,
        },
    },
};
$c->mock( config => sub {$config} );

is( $c->authenticate_hatena_url, $auth_url, 'returns auth_url correctly' );

my $req = Test::MockObject->new;
my $res = Test::MockObject->new;

$res->{name} = 'hatena';

$res->fake_module('Hatena::API::Auth::User', name => sub { shift->{name} });

my $params = {};
$req->fake_module('Catalyst::Request');
$req->mock( params           => sub {$params} );
$c->mock( req                => sub {$req} );
$c->mock( default_auth_store => sub { } );
$c->mock( set_authenticated  => sub { } );
$c->mock( debug              => sub {0} );

my $method;
$hatena->mock( login => sub { $res } );

ok( !$c->authenticate_hatena, 'auth failes without cert parameter' );

$params->{cert} = 'my_cert';

ok( $c->authenticate_hatena, 'auth successful with cert' );

