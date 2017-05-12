use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 6;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok('Foo');
my $t = $cluster->t;

$t->get_ok('/cluster')
  ->status_is(200)
  ->content_is('Cluster plugin');

$t->get_ok('/mojo')
  ->status_is(404);

__DATA__

@@ lib/Foo.pm
package Foo;

use strict;
use warnings;
use Mojo::Base qw( Clustericious::App );

sub startup
{
  my($self) = @_;
  $self->SUPER::startup;
  $self->plugin('MyPlug');
}

1;


@@ lib/Mojolicious/Plugin/MyPlug.pm
package Mojolicious::Plugin::MyPlug;

use strict;
use warnings;
use Mojo::Base qw( Mojolicious::Plugin );

sub register
{
  my($self, $app) = @_;
  
  $app->routes->get('/mojo')->to(cb => sub {
    shift->render(text => 'Mojo plugin');
  });
}

1;


@@ lib/Clustericious/Plugin/MyPlug.pm
package Clustericious::Plugin::MyPlug;

use strict;
use warnings;
use Mojo::Base qw( Mojolicious::Plugin );

sub register
{
  my($self, $app) = @_;
  
  $app->routes->get('/cluster')->to(cb => sub {
    shift->render(text => 'Cluster plugin');
  });
}

1;
