#!perl

use 5.020;
use warnings;
use strict;

use Test::More;
use Test::Exception;
use Test::Consul 0.009;

use AnyEvent;
use AnyEvent::Consul;
use AnyEvent::Consul::Exec;

my $tc1 = eval { Test::Consul->start };
my $tc2 = eval { Test::Consul->start };

SKIP: {
  skip "consul test environment not available", 1, unless $tc1 && $tc2;

  $tc1->wan_join($tc2);

  my $c2_pid = $tc2->_pid;

  my $cv = AE::cv;

  my $returned_pid;

  my $e = AnyEvent::Consul::Exec->new(
    consul_args => [ port => $tc1->port ],

    dc => $tc2->datacenter,

    command => 'echo $PPID',

    on_output => sub {
      my ($node, $out) = @_;
      chomp $out;
      $returned_pid = $out;
    },

    on_done => sub {
      $cv->send;
    },

    on_error => sub {
      warn @_;
      $cv->send;
    },
  );

  $e->start;
  $cv->recv;

  is $c2_pid, $returned_pid, "cross-datacenter command submitted in one dc was run in the other";
}

done_testing;
