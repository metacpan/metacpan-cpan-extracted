use strict;
use warnings;
use autodie;
use 5.010;
use Test::Clustericious::Log;
use Test::More;
use Test::Clustericious::Cluster;

$Clustericious::VERSION //= 0.9925;

my $cluster = Test::Clustericious::Cluster->new;

our $status = {};

subtest 'prep' => sub {
  plan tests => 2;

  $cluster->create_plugauth_lite_ok(
    auth  => sub { $status->{auth}     // die },
    authz => sub { $status->{authz}    // die },
    host  => sub { $status->{trusted}  // die },
  );

  $cluster->create_cluster_ok(qw( SomeService ));

  note "urls = " . join(', ', map { $_ . '' } @{ $cluster->urls });
  note "apps = " . join(', ', map { ref } @{ $cluster->apps });

};

my $t = $cluster->t;
$cluster->apps->[0]->ua->inactivity_timeout(1);

subtest 'simple get without authentication' => sub {
  plan tests => 3;
  my $url = $cluster->url->clone;

  $t->get_ok($url)
    ->status_is(200)
    ->content_is('hello');
};

subtest 'request private url without authentication' => sub {
  plan tests => 3;
  my $url = $cluster->url->clone;

  $t->get_ok("$url/private")
    ->status_is(401)
    ->content_is('auth required');
};

subtest 'test against an auth server that appears to be down, or spewing internal errors' => sub {
  plan tests => 3;
  my $url = $cluster->url->clone;  
  $url->userinfo('foo:bar');

  $url->path('/private');
  $t->get_ok($url)
    ->status_is(503)
    ->content_is('auth server down');
};

subtest 'non VIP host making request, authentication credentials are ok and user is authorized' => sub {
  plan tests => 3;
  my $url = $cluster->url->clone;
  $url->userinfo('foo:bar');

  local $status = { 
    trusted => 0,
    auth    => 1,
    authz   => 1,
  };

  $url->path('/private');
  $t->get_ok($url)
    ->status_is(200)
    ->content_is('this is private');    
};

subtest "host is trusted, credentials wouldn't check out, but users is authorized" => sub {
  plan tests => 3;
  my $url = $cluster->url->clone;
  $url->userinfo('foo:bar');
  
  local $status = {
    trusted => 1,
    auth    => 0,
    authz   => 1,
  };

  $url->path('/private');
  $t->get_ok($url)
    ->status_is(200)
    ->content_is('this is private');
};

subtest 'non VIP host making request with bad credentials, user is authorized' => sub {
  plan tests => 3;
  my $url = $cluster->url->clone;
  $url->userinfo('foo:bar');

  local $status = {
    trusted => 0,
    auth    => undef,
    authz   => 1,
  };

  $url->path('/private');
  $t->get_ok($url)
    ->status_is(503)
    ->content_is('auth server down');
};

subtest 'non VIP host making request with good credentials, authz server is DOWN' => sub {
  plan tests => 3;
  my $url = $cluster->url->clone;
  $url->userinfo('foo:bar');

  local $status = {
    trusted => 0,
    auth    => 1,
    authz   => undef,
  };

  $url->path('/private');
  $t->get_ok($url)
    ->status_is(503)
    ->content_is('auth server down');

};

subtest 'non VIP host making request with good credentials, but user is not authorized' => sub {
  plan tests => 3;
  my $url = $cluster->url->clone;
  $url->userinfo('foo:bar');

  local $status = {
    trusted => 0,
    auth    => 1,
    authz   => 0,
  };

  $url->path('/private');
  $t->get_ok($url)
    ->status_is(403)
    ->content_is('unauthorized');
};


subtest 'non VIP host making request with bad credentials, but user IS authorized' => sub {
  plan tests => 3;
  my $url = $cluster->url->clone;
  $url->userinfo('foo:bar');

  local $status = {
    trusted => 0,
    auth    => 0,
    authz   => 1,
  };

  $url->path('/private');
  $t->get_ok($url)
    ->status_is(401)
    ->content_is('authentication failure');
};

Test::Clustericious::Log::log_unlike(qr{HASH\(0x}, 'no hashrefs');

done_testing;

__DATA__

@@ etc/SomeService.conf
---
url: <%= cluster->url %>
plug_auth:
  url: <%= cluster->auth_url %>/


@@ lib/SomeService.pm
package SomeService;

use strict;
use warnings;
our $VERSION = '1.1';
use base 'Clustericious::App';
use SomeService::Routes;

1;


@@ lib/SomeService/Routes.pm
package SomeService::Routes;

use Clustericious::RouteBuilder;

get '/' => sub { shift->render(text => 'hello'); };

authenticate;
authorize;

get '/private' => sub { shift->render(text => 'this is private'); };

1;
