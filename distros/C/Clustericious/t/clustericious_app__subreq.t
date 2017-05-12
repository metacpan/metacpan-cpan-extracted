use strict;
use warnings;
use 5.010;
use Test::Clustericious::Cluster;
use Test::More tests => 4;

$Clustericious::VERSION //= 0.9925;

my $cluster = Test::Clustericious::Cluster->new;

subtest 'prep' => sub {
  plan tests => 2;

  $cluster->create_plugauth_lite_ok(
    auth => sub {
      my($user, $pass) = @_;
      return $user eq 'foo' && $pass eq 'bar';
    },
  );

  $cluster->create_cluster_ok(qw( MyApp ));

  note "urls = " . join(', ', map { $_ . '' } @{ $cluster->urls });
  note "apps = " . join(', ', map { ref } @{ $cluster->apps });

};

note "urls = " . join(', ', map { $_ . '' } @{ $cluster->urls });
note "apps = " . join(', ', map { ref } @{ $cluster->apps });

my $t   = $cluster->t;

subtest 'unauthenticated' => sub {
  plan tests => 4;

  my $url = $cluster->url->clone;

  $t->get_ok("$url/")
    ->status_is(200);
 
  $t->get_ok("$url/private")
    ->status_is(401);
};

subtest 'auth with foo:bar' => sub {

  plan tests => 2;

  my $url = $cluster->url->clone;
  $url->userinfo('foo:bar');
  $url->path('/private');
  $t->get_ok($url)
    ->status_is(200);

};

subtest 'subrequest avoids auth' => sub {
  plan tests => 5;

  my $url = $cluster->url->clone;
  $url->userinfo('foo1:ba1r');

  $t->get_ok("$url/private")
    ->status_is(401);

  $url = $cluster->url->clone;

  $t->get_ok("$url/indirect")
    ->status_is(200)
    ->content_is('this is private');
};

__DATA__

@@ etc/MyApp.conf
---
url: <%= cluster->url %>
plug_auth:
  url: <%= cluster->auth_url %>
  plugin: PlugAuth2


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

get '/' => sub { shift->render(text => 'hello') };

get '/indirect' => sub {
  my($self) = @_;
  my $tx = $self->ua->transactor->tx( GET => '/private');
  $tx->{plug_auth_skip_auth} = 1;
  $self->app->handler($tx);
  my $res = $tx->success;
  $self->render( text => $res->body, status => $res->code );
};

authenticate;
authorize;

get '/private' => sub { shift->render(text => 'this is private') };

1;


@@ lib/Clustericious/Plugin/PlugAuth2.pm
package Clustericious::Plugin::PlugAuth2;

use strict;
use warnings;
use base qw( Clustericious::Plugin::PlugAuth );

sub authenticate {
  return 1 if $_[1]->tx->{plug_auth_skip_auth};
  return shift->SUPER::authenticate(@_);
};

sub authorize {
  return 1 if $_[1]->tx->{plug_auth_skip_auth};
  return shift->SUPER::authenticate(@_);
};

1;
