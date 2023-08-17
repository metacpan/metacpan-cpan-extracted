#!perl

use 5.020;
use warnings;
use strict;

use Test::More;
use Test::Exception;
use Test::Consul 0.011;

use AnyEvent;
use AnyEvent::Consul;
use AnyEvent::Consul::Exec;

my $tc1 = eval { Test::Consul->start(enable_remote_exec => 1) };
my $tc2 = eval { Test::Consul->start(enable_remote_exec => 1,
                                     datacenter => $tc1->datacenter) };

SKIP: {
  skip "consul test environment not available", 1, unless $tc1 && $tc2;

  $tc1->join($tc2);

  my $cv = AE::cv;

  my %exited;

  my $e = AnyEvent::Consul::Exec->new(
    consul_args => [ port => $tc1->port ],

    node => '.*',
    min_node_count => 2,

    command => 'echo $PPID',

    on_exit => sub {
      my ($node, $rc) = @_;

      $exited{$node} = $rc;
    },

    on_done => sub {
      $cv->send;
    },

    on_error => sub {
      diag @_;
      $cv->send;
    },
  );

  $e->start;
  $cv->recv;

  is($exited{$tc1->node_name}, 0, 'first node exited');
  is($exited{$tc2->node_name}, 0, 'second node exited');
}

done_testing;
