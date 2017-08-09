#!perl

use 5.020;
use warnings;
use strict;

use Test::More;
use Test::Exception;
use Test::Consul;

use AnyEvent;
use AnyEvent::Consul;
use AnyEvent::Consul::Exec;

my $tc = eval { Test::Consul->start };

SKIP: {
  skip "consul test environment not available", 5, unless $tc;

  my ($submit, $ack, $output, $exit, $done);
  my $sid;
  
  my $cv = AE::cv;

  my $e; $e = AnyEvent::Consul::Exec->new(
    consul_args => [ port => $tc->port ],

    command => 'uptime',

    on_submit => sub {
      $submit = 1;
      $sid = $e->{_sid};
    },

    on_ack => sub {
      $ack = 1;
    },

    on_output => sub {
      $output = 1;
    },

    on_exit => sub {
      $exit = 1;
    },

    on_done => sub {
      $done = 1;
      $cv->send;
    },

    on_error => sub {
      my ($err) = @_;
      die $err;
    },
  );

  $e->start;
  $cv->recv;

  ok $submit, "job submitted";
  ok $ack, "acknowledged";
  ok $output, "received output";
  ok $exit, "exited";
  ok $done, "job done";

  my $c = Consul->new(port => $tc->port);

  my ($session) = $c->session->info($sid);
  is $session, undef, "session destroyed";

  my $kv = $c->kv->get_all("_rexec/$sid");
  is scalar @$kv, 0, "all KVs destroyed";
}

done_testing;
