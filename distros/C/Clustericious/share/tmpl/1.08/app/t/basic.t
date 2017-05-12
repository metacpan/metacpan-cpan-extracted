% my $class = shift;
use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 4;
use <%= $class %>;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok('<%= $class %>');
my $t = $cluster->t;

$t->get_ok('/')
  ->status_is(200)
  ->content_is('welcome to <%= $class %>');

__DATA__

@@ etc/<%= $class %>.conf
---
url: <<%= '%' %>= cluster->url <%= '%' %>>

