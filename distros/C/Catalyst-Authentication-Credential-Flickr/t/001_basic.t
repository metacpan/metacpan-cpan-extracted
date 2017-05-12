#!perl

use strict;
use Test::MockObject;
use Test::More tests => 8;

my ($flickr, $resp, $tree);

BEGIN {
    $tree = {
       'children' => [{ }, {
          'children' => [{
             'name' => 'token',
             'children' => [{ 'content' => 'T0K3N' } ],
          },{
             'name' => 'perms',
             'children' => [{ 'content' => 'read' } ],
          },{
             'name' => 'user',
             'children' => [],
             'attributes' => { 'fullname' => 'b10m', 'nsid' => '1337@N00',
                               'username' => 'BLOM' }
          }]
       }]
    };
    $resp   = Test::MockObject->new(); 
    $resp->{tree} = $tree;

    $flickr = Test::MockObject->new();
    $flickr->fake_module("Flickr::API");
    $flickr->fake_new("Flickr::API");
    $flickr->mock( request_auth_url => sub {"http://example.com/flickr"});
    $flickr->mock( execute_method   => sub { $resp });

    use_ok( 'Catalyst::Authentication::Credential::Flickr' );
}

my $config = {
    key    => 'flickr-key-here',
    secret => 'flickr-secret-here',
    perms  => 'read',
};

my $req    = Test::MockObject->new();
   $req->mock( params => sub { { frob => 'frob'} } );
my $c      = Test::MockObject->new();
   $c->mock( req   => sub { $req } );
   $c->mock( debug => sub { 1 } );
   $c->mock( log   => sub { 1 } );
my $realm  = Test::MockObject->new();
   $realm->mock( find_user => sub { $_[1] });
$realm->{config} = {};

my $m = Catalyst::Authentication::Credential::Flickr->new($config, $c, $realm);
can_ok($m, qw/new authenticate authenticate_flickr_url/);

my $redirect = $m->authenticate_flickr_url($c);
is($redirect, "http://example.com/flickr", "redirect url ok");

my $user = $m->authenticate($c, $realm, {});

is($user->{fullname}, 'b10m');
is($user->{nsid}, '1337@N00');
is($user->{perms}, 'read');
is($user->{token}, 'T0K3N');
is($user->{username}, 'BLOM');
