use strict;
use warnings;
use Test::More tests => 2;
use Test::Clustericious::Log diag => 'NONE';
use Test::Clustericious::Cluster;

$Clustericious::VERSION //= 0.9925;

my $cluster = Test::Clustericious::Cluster->new;

subtest 'prep' => sub {
  plan tests => 1;

  $cluster->create_cluster_ok(qw( MyApp ));

  note "urls = " . join(', ', map { $_ . '' } @{ $cluster->urls });
  note "apps = " . join(', ', map { ref } @{ $cluster->apps });

};

my $t = $cluster->t;

subtest 'basic auth, no vip hosts and authz ok' => sub {
  plan tests => 3;

  my $url = $cluster->url->clone;

  $t->get_ok("$url/public")
    ->status_is(500)
    ->content_like(qr{FOO Bar baz});
    
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
  shift->reply->exception('FOO Bar baz');
};

1;

