use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 4;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok('MyApp');
isa_ok $cluster->apps->[0], 'Clustericious::App';

my $t = $cluster->t;
my $url = $cluster->url;

subtest 'with url' => sub {
  plan tests => 3;
  $t->get_ok("$url/foo")
    ->status_is(200)
    ->content_is('Hello World!');
};

subtest 'with outurl' => sub {
  plan tests => 3;
  $t->get_ok("/foo")
    ->status_is(200)
    ->content_is('Hello World!');
};

__DATA__

@@ lib/MyApp.pm
package MyApp;
  
use strict;
use warnings;
use Mojo::Base qw( Clustericious::App );

package MyApp::Routes;

use Clustericious::RouteBuilder;

get '/foo' => sub {
  shift->render(text => 'Hello World!');
};

1;
