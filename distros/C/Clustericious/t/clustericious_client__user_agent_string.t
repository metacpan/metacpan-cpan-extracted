use strict;
use warnings;
use 5.010;
use Test::Clustericious::Cluster 0.22;
use Test::More tests => 2;

my $cluster = Test::Clustericious::Cluster->new;

## TODO: T::C::C should do this automagically
#Clustericious::Client->_mojo_user_agent_factory(sub { $cluster->create_ua });

subtest 'prep' => sub {
  # TODO: T::C::C should fail if when it autoloads something it fails (?)
  require_ok 'MyApp';
  $cluster->create_cluster_ok(qw( MyApp ));
  note "urls = " . join(', ', map { $_ . '' } @{ $cluster->urls });
  note "apps = " . join(', ', map { ref } @{ $cluster->apps });
};

my $t   = $cluster->t;
my $url = $cluster->url->clone;

subtest 'get user agent string' => sub {
  require_ok 'MyApp::Client';
  my $client = MyApp::Client->new;  
  my $expected = "Clustericious::Client/@{[ $Clustericious::Client::VERSION // 'dev' ]} MyApp::Client/1.02";
  is $client->ua->transactor->name, $expected, 'name matches on the client side';
  is $client->getua, $expected, 'name matches on the server side';
};

__DATA__

@@ etc/MyApp.conf
---
url: <%= cluster->url %>


@@ lib/MyApp.pm
package MyApp;

use strict;
use warnings;
use Mojo::Base qw( Clustericious::App );
use MyApp::Routes;

1;


@@ lib/MyApp/Routes.pm
package MyApp::Routes;

use strict;
use warnings;
use Clustericious::RouteBuilder;

get '/getua' => sub {
  my($c) = @_;
  use Test::More;
  note $c->req->to_string;
  $c->render( text => $c->req->headers->user_agent, status => 200 );
};  

1;


@@ lib/MyApp/Client.pm
package MyApp::Client;

use strict;
use warnings;
use Clustericious::Client;
our $VERSION = '1.02';

route getua => GET => '/getua';

1;
