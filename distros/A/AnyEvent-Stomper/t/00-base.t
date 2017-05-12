use 5.008000;
use strict;
use warnings;

use Test::More tests => 43;

my $t_client_class;
my $t_cluster_class;
my $t_frame_class;
my $t_err_class;

BEGIN {
  $t_client_class = 'AnyEvent::Stomper';
  use_ok( $t_client_class );

  $t_cluster_class = 'AnyEvent::Stomper::Cluster';
  use_ok( $t_cluster_class );

  $t_frame_class = 'AnyEvent::Stomper::Frame';
  use_ok( $t_frame_class );

  $t_err_class = 'AnyEvent::Stomper::Error';
  use_ok( $t_err_class );
}

can_ok( $t_client_class, 'new' );
my $stomper = new_ok( $t_client_class => [ lazy => 1 ] );

can_ok( $stomper, 'execute' );
can_ok( $stomper, 'send' );
can_ok( $stomper, 'subscribe' );
can_ok( $stomper, 'unsubscribe' );
can_ok( $stomper, 'ack' );
can_ok( $stomper, 'nack' );
can_ok( $stomper, 'begin' );
can_ok( $stomper, 'commit' );
can_ok( $stomper, 'abort' );
can_ok( $stomper, 'disconnect' );
can_ok( $stomper, 'force_disconnect' );

can_ok( $t_cluster_class, 'new' );
my $cluster = new_ok( $t_cluster_class,
  [ nodes => [
      { host => '172.18.0.2', port => 61613 },
      { host => '172.18.0.3', port => 61613 },
      { host => '172.18.0.4', port => 61613 },
    ],
  ]
);

can_ok( $cluster, 'execute' );
can_ok( $cluster, 'send' );
can_ok( $cluster, 'subscribe' );
can_ok( $cluster, 'unsubscribe' );
can_ok( $cluster, 'ack' );
can_ok( $cluster, 'nack' );
can_ok( $cluster, 'begin' );
can_ok( $cluster, 'commit' );
can_ok( $cluster, 'abort' );
can_ok( $cluster, 'force_disconnect' );
can_ok( $cluster, 'nodes' );

my @nodes = $cluster->nodes;
is ( scalar @nodes, 3, 'cluster; get all nodes; number' );
foreach my $node (@nodes) {
  isa_ok( $node, 'AnyEvent::Stomper' );
}

can_ok( $t_frame_class, 'new' );
my $frame = new_ok( $t_frame_class => [ 'MESSAGE', { 'message-id' => '123' },
    'Hello, world!' ] );

can_ok( $frame, 'command' );
can_ok( $frame, 'headers' );
can_ok( $frame, 'body' );

can_ok( $t_err_class, 'new' );
my $err = new_ok( $t_err_class => [ 'Some error', 6 ] );

can_ok( $err, 'message' );
can_ok( $err, 'code' );
