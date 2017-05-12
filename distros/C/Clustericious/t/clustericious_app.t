use strict;
use warnings;
use Test::Clustericious::Log note => 'INFO..ERROR', diag => 'FATAL';
use Test::Clustericious::Cluster;
use Test::More tests => 33;
use Capture::Tiny qw( capture );
use YAML::XS qw( Load );

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok('SomeService');
my $t = $cluster->t;

$t->get_ok("/")
  ->status_is(200)
  ->content_like(qr/hello/, "got content");

$t->get_ok('/version')
    ->status_is(200,'GET /version')
    ->json_is('', [$SomeService::VERSION], '/version is correct');

$t->get_ok('/version.yml')
    ->status_is(200, 'GET /version.yml')
    ->header_is('Content-Type', 'text/x-yaml');

is eval { Load($t->tx->res->body)->[0] }, $SomeService::VERSION, '/version.yml is correct';
diag $@ if $@;

note $t->tx->res->body;

# trying to get meta data for a bogus table should not
# return 500 when Rose::Planter is not loaded.
$t->get_ok('/api/bogus_table')
    ->status_is(404);

$t->get_ok('/api')
    ->status_is(200);

my $url = $t->ua->server->url;

$t->get_ok("${url}autotest")
  ->status_is(200)
  ->json_is({ a => 1, b => 2 });

SKIP: {
  # This test stopped working in Mojo 6.32 without the double //
  # for very mysterious reasons.  I've duplicated this test
  # with Test::Clustericious::Cluster in t/hello_world.t and it
  # works there.  It also worked fine in the browser.  I am also
  # pretty sure that we don't actually use this... so... I
  # am just going to skip this test for now.
  # see https://github.com/plicease/Clustericious/issues/20
  skip 'skip test broken by Mojo 6.32', 2;
  #$t->get_ok("//autotest.yml")
  $t->get_ok("/autotest.yml")
    ->status_is(200);
  note $t->tx->res->text;
};

$t->get_ok('/autotest_not_found')
  ->status_is(404);
note $t->tx->res->text;

my($out,$err,$ret) = capture {
  local @ARGV = 'routes';
  local $ENV{MOJO_APP} = 'SomeService';
  Clustericious::Commands->start;
};
note "[routes]\n$out" if $out;
note "[err]\n$err" if $err;

$t->get_ok('/bogus/not/here')
  ->status_is(404)
  ->content_like(qr{^NOT FOUND: "/bogus/not/here"});

$t->get_ok('/force/exception')
  ->status_is(500)
  ->content_like(qr{^ERROR: this is an exception});

$t->get_ok('/url_for1')
  ->status_is(200)
  ->content_is('/autotest');

$t->get_ok('/url_for2')
  ->status_is(200);

note $t->tx->res->to_string;

__DATA__


@@ etc/SomeService.conf
---
url: <%= cluster->url %>
url_base: http://1.2.3.4:5678

@@ lib/SomeService.pm
package SomeService;

$SomeService::VERSION = '867.5309';

use base 'Clustericious::App';
use Clustericious::RouteBuilder;

get '/' => sub { shift->render(text => "hello"); };

get '/autotest' => sub { shift->stash->{autodata} = { a => 1, b => 2 } };

get '/autotest_not_found' => sub {
  my($self) = shift;
  $self->stash->{autodata} = [1,2,3];
  $self->reply->not_found;
};

get '/force/exception' => sub {
  die "this is an exception";
};

get '/url_for1' => sub {
  my($self) = @_;
  $self->render(text => $self->url_for('/autotest'));
};

get '/url_for2' => sub {
  my($self) = @_;
  $self->render(text => $self->url_for('/autotest?foo=bar'));
};

1;
