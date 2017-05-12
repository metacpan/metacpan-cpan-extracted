use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 5;
use YAML::XS ();
use JSON::MaybeXS qw( decode_json );
use Clustericious::HelloWorld::Client;
use Clustericious::Commands;
use Capture::Tiny qw( capture );

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok('Clustericious::HelloWorld');

my $url = $cluster->url;
my $t = $cluster->t;

subtest '/' => sub {
  plan tests => 3;

  $t->get_ok("$url/")
    ->status_is(200)
    ->content_is('Hello, world');

};

subtest '/status' => sub {
  plan tests => 2;

  subtest json => sub {
    plan tests => 4;
    $t->get_ok("$url/status")
      ->status_is(200);
    unlike $t->tx->res->body, qr{^---}, 'is not YAML';
    is decode_json($t->tx->res->body)->{app_name}, 'Clustericious::HelloWorld', 'app_name';
  };
  
  subtest yaml => sub {
    plan tests => 4;
    $t->get_ok("$url/status.yml")
      ->status_is(200);
    like $t->tx->res->body, qr{^---}, 'is YAML';
    is YAML::XS::Load($t->tx->res->body)->{app_name}, 'Clustericious::HelloWorld', 'app_name';
  };

};

subtest '/modules' => sub {
  plan tests => 2;
  
  subtest json => sub {
    plan tests => 4;
    $t->get_ok("$url/modules")
      ->status_is(200);
    unlike $t->tx->res->body, qr{^---}, 'is not YAML';
    is decode_json($t->tx->res->body)->{'Clustericious/HelloWorld.pm'}, $INC{'Clustericious/HelloWorld.pm'}, 'content makes sense';
  };
  
  subtest yaml => sub {
    plan tests => 4;
    $t->get_ok("$url/modules.yml")
      ->status_is(200);
    like $t->tx->res->body, qr{^---}, 'is YAML';
    is YAML::XS::Load($t->tx->res->body)->{'Clustericious/HelloWorld.pm'}, $INC{'Clustericious/HelloWorld.pm'}, 'content makes sense';
  };

};

subtest 'Clustericious::HelloWorld::Client' => sub {
  plan skip_all => 'for now';
  
  my $client = Clustericious::HelloWorld::Client->new;
  isa_ok $client, 'Clustericious::HelloWorld::Client';

  subtest '/status' => sub {
    my $status = $client->status;
    is $status->{app_name} , 'Clustericious::HelloWorld', 'app_name';
  };

};

my($out,$err,$ret) = capture {
  local @ARGV = 'routes';
  local $ENV{MOJO_APP} = 'Clustericious::HelloWorld';
  Clustericious::Commands->start;
};
note "[routes]\n$out" if $out;
note "[err]\n$err" if $err;

__END__

@@ etc/Hello-World.conf
---
url: <%= cluster->url %>


