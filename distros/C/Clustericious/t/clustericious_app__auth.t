use strict;
use warnings;
use Test::More tests => 4;
use Test::Clustericious::Cluster;

$Clustericious::VERSION //= 0.9925;

my $cluster = Test::Clustericious::Cluster->new;

our $is_host_vip = 0;
our $is_authz_ok = 1;

subtest 'prep' => sub {
  plan tests => 2;

  $cluster->create_plugauth_lite_ok(
    host => sub {
      my($host, $tag) = @_;
      return $is_host_vip;
    },
    auth => sub {
      my($user, $pass) = @_;
      if($user eq 'foo' && $pass eq 'bar')
      { return 1 }
      else
      { return 0 }
    },
    authz => sub {
      my($user, $action, $resource) = @_;
      return $is_authz_ok;
    },
  );

  $cluster->create_cluster_ok(qw( MyApp ));

  note "urls = " . join(', ', map { $_ . '' } @{ $cluster->urls });
  note "apps = " . join(', ', map { ref } @{ $cluster->apps });

};

my $t   = $cluster->t;

subtest 'basic auth, no vip hosts and authz ok' => sub {
  plan tests => 10;

  my $url = $cluster->url->clone;

  $t->get_ok("$url/public")
    ->status_is(200)
    ->content_like(qr{this message is public});
  $t->get_ok("$url/private")
    ->status_is(401);

  $url->userinfo('foo:baz');
  
  $url->path('/private');
  $t->get_ok($url)
    ->status_is(401);

  $url->userinfo('foo:bar');

  $t->get_ok($url)
    ->status_is(200)
    ->content_like(qr{this message is private});
    
};

subtest 'vip host' => sub {
  plan tests => 11;

  local $is_host_vip = 1;
  
  my $url = $cluster->url->clone;

  $t->get_ok("$url/public")
    ->status_is(200)
    ->content_like(qr{this message is public});
  $t->get_ok("$url/private")
    ->status_is(401);

  $url->userinfo('foo:baz');
  
  $url->path('/private');
  $t->get_ok($url)
    ->status_is(200)
    ->content_like(qr{this message is private});

  $url->userinfo('foo:bar');

  $t->get_ok($url)
    ->status_is(200)
    ->content_like(qr{this message is private});
  
};

subtest 'auth but not authz' => sub {

  local $is_authz_ok = 0;

  my $url = $cluster->url->clone;

  $t->get_ok("$url/public")
    ->status_is(200)
    ->content_like(qr{this message is public});
  $t->get_ok("$url/private")
    ->status_is(401);

  $url->userinfo('foo:baz');
  
  $url->path('/private');
  $t->get_ok($url)
    ->status_is(401);

  $url->userinfo('foo:bar');

  $t->get_ok($url)
    ->status_is(403);

};

__DATA__

@@ etc/MyApp.conf
---
url: <%= cluster->url %>
plug_auth:
  url: <%= cluster->auth_url %>


@@ lib/MyApp.pm
package MyApp;

use strict;
use warnings;
use Mojo::Base qw( Clustericious::App );
use MyApp::Routes;
our $VERSION = '1.00';

1;


@@ lib/MyApp/Routes.pm
package MyApp::Routes;

use strict;
use warnings;
use Clustericious::RouteBuilder;

get '/public' => sub {
  shift->render(text => 'this message is public');
};

authenticate;
authorize;

get '/private' => sub {
  shift->render(text => 'this message is private');
};

1;

