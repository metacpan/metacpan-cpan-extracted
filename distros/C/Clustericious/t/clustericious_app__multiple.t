use strict;
use warnings;
use 5.010;
use Test::Clustericious::Cluster;
use Test::More tests => 5;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( Clustericious::HelloWorld Clustericious::HelloWorld ));
my $t = $cluster->t;

$t->get_ok($cluster->urls->[0]);

is $cluster->apps->[0]->config->x, 1;

$t->get_ok($cluster->urls->[1]);

is $cluster->apps->[1]->config->x, 3;

__DATA__

@@ etc/Clustericious-HelloWorld.conf
---
x: <%= cluster->index == 0 ? 1 : 3 %>
y: <%= cluster->index == 0 ? 2 : 4 %>
