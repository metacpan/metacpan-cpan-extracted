#!/usr/bin/perl

use strict;
use warnings;

use Test::Exception;
use Test::MockObject::Extends;
use Test::MockObject;
use Test::More tests => 7;

use HTTP::Response;

my $m;
BEGIN {
    use_ok( $m = 'Catalyst::Plugin::Authentication::Credential::Flickr' );
}

can_ok( $m, 'authenticate_flickr' );
can_ok( $m, 'authenticate_flickr_url' );

my $flickr   = Test::MockObject->new;
my $auth_url = 'http://example.com/auth/url';
$flickr->mock( request_auth_url => sub {$auth_url} );

my $c = Test::MockObject::Extends->new($m);

my $user_class = Test::MockObject->new;
$user_class->fake_module('Fake::User::Class', new => sub {});

my $config = {
    authentication => {
        flickr => {
            key        => 'my_key',
            secret     => 'my_secret',
            perms      => 'write',
            user_class => 'Fake::User::Class',

            flickr_object => $flickr,
        },
    },
};
$c->mock( config => sub {$config} );

is( $c->authenticate_flickr_url, $auth_url, 'returns auth_url correctly' );

my $req        = Test::MockObject->new;
my $res        = HTTP::Response->new;

my $params     = {};
$res->{success} = 1;
$req->fake_module('Catalyst::Request');
$req->mock( params => sub {$params} );
$c->mock( req                => sub {$req} );
$c->mock( default_auth_store => sub { } );
$c->mock( set_authenticated  => sub { } );
$c->mock( debug => sub { 0 } );

my $method;
$flickr->mock( execute_method => sub { $method = $_[1]; $res } );

ok( !$c->authenticate_flickr, 'auth failes without frob parameter' );

$params->{frob} = 'my_frob';

ok( $c->authenticate_flickr, 'auth successful with frob' );
is( $method, 'flickr.auth.getToken', 'call flickr.auth.getToken');
