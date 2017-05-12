use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 2;
use Mojo::URL;
use Test::Warn;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok('Foo');
my $app = $cluster->apps->[0];
my $t = $cluster->t;

subtest render_moved => sub {
  plan tests => 6;

  $t->get_ok('/foo')
    ->status_is(301);

  my $location = Mojo::URL->new($t->tx->res->headers->location);
  is $location->path, '/bar', 'location path';
  
  $t->get_ok($location)
    ->status_is(200)
    ->content_is('BAR');
};

__DATA__

@@ lib/Foo.pm
package Foo;

use strict;
use warnings;
use Mojo::Base qw( Mojolicious );

our $VERSION = '1.23';

sub startup
{
  my($self) = @_;

  $self->plugin('Clustericious::Plugin::ClustericiousHelpers');
  
  $self->routes->get('/foo')->to(cb => sub {
    my($c) = @_;
    $c->render_moved('/bar');
  });
  
  $self->routes->get('/bar')->to(cb => sub {
    my($c) = @_;
    $c->render(text => 'BAR');
  });
}

1;
