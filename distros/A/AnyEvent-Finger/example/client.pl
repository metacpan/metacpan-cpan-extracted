#!/usr/bin/perl

use strict;
use warnings;
use AnyEvent;
use AnyEvent::Finger::Client;

my $done = AnyEvent->condvar;

my $client = AnyEvent::Finger::Client->new;

$client->finger(shift @ARGV, sub {
  my($lines) = @_;
  print "[response]\n";
  print join "\n", @$lines;
  print "\n";
  $done->send;
}, on_error => sub {
  print STDERR shift;
  print STDERR "\n"
  $done->send;
});

$done->recv;
