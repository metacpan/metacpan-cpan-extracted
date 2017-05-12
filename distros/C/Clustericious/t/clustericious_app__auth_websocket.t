use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 18;
use PlugAuth::Lite;
use Clustericious;

$Clustericious::VERSION //= 0.9925;

my $cluster = Test::Clustericious::Cluster->new;

$cluster->create_plugauth_lite_ok(
  auth => sub {
    my($user, $pass) = @_;
    if($user eq 'foo' && $pass eq 'bar')
    { return 1 }
    else
    { return 0 }
  }
);

$cluster->create_cluster_ok(qw( MyApp ));

my $url = $cluster->url->clone;
my $t   = $cluster->t;

$t->get_ok("$url/private")
  ->status_is(401);

$t->websocket_ok("$url/echo1")
  ->send_ok('hello')
  ->message_ok
  ->message_is('hello')
  ->finish_ok;

do {
  my($ua, $tx);
  my $ws = $t->ua->websocket(
    "$url/echo2" => sub {
      ($ua, $tx) = @_;
      Mojo::IOLoop->stop;
    }
  );
  Mojo::IOLoop->start;
  #note $tx->res->to_string;
  is $tx->res->code, 401, 'code = 401';
};

$url->userinfo('foo:bar');

sub url ($$)
{
  my($url, $path) = @_;
  $url->clone;
  $url->path($path);
  $url;
}

$t->get_ok(url $url, '/private' )
  ->status_is(200);

do {
  my($ua, $tx);
  my $ws = $t->ua->websocket(
    url($url, '/echo2') => sub {
      ($ua, $tx) = @_;
      Mojo::IOLoop->stop;
    }
  );
  Mojo::IOLoop->start;
  #note $tx->res->to_string;
  is $tx->res->code, 101, 'code = 101';
};

$t->websocket_ok(url $url, '/echo2')
  ->send_ok('hello')
  ->message_ok
  ->message_is('hello')
  ->finish_ok;

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

websocket '/echo1' => sub {
  my($self) = @_;
  $self->on(message => sub {
    my($self, $payload) = @_;
    $self->send($payload);
  });
};

authenticate;

get '/private' => sub {
  shift->render(text => 'hello there from bar')
};

websocket '/echo2' => sub {
  my($self) = @_;
  $self->on(message => sub {
    my($self, $payload) = @_;
    $self->send($payload);
  });
};

1;
