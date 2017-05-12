use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 7;

# TODO: make a public interface which does some of
# the complicated stuff that is currently in
# C::RB::Alt below.

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok('Foo','Bar');
my(@url) = @{ $cluster->urls };
my $t = $cluster->t;

$t->get_ok("$url[0]/foo")
  ->status_is(200)
  ->content_is('GORP GORP');

$t->get_ok("$url[1]/bar")
  ->status_is(200)
  ->content_is('GORP GORP');

__DATA__

@@ lib/Foo.pm
package Foo;

use strict;
use warnings;
use base qw( Clustericious::App );
use Foo::Routes;

1;


@@ lib/Foo/Routes.pm
package Foo::Routes;

use strict;
use warnings;
use Clustericious::RouteBuilder::Alt;

gorp '/foo';

1;

@@ lib/Bar.pm
package Bar;

use strict;
use warnings;
use base qw( Clustericious::App );
use Clustericious::RouteBuilder::Alt;

gorp '/bar';

1;


@@ lib/Clustericious/RouteBuilder/Alt.pm
package Clustericious::RouteBuilder::Alt;

use strict;
use warnings;
use Mojo::Util qw( monkey_patch );

sub import
{
  my $caller = caller;
  my $app_class = $caller;
  $app_class =~ s/::Routes//;

  my %gorp = ();

  monkey_patch $app_class, startup_route_builder => sub {
    my($app) = @_;
    $app->routes->get($_)->to(cb => sub {
      my($self) = @_;
      $self->render(text => 'GORP GORP');
    }) for @{ $gorp{$app_class} };
  };
  
  monkey_patch $caller, gorp => sub {
    my($path) = @_;
    push @{ $gorp{$app_class} }, $path;
  };
}

1;

