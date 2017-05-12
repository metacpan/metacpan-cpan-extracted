#!/usr/bin/perl
use lib '../lib';
use strict;
use warnings;
use Coro;
use Coro::Event;
use Devel::Size qw(size total_size);
use Data::Dumper;

use Continuity;
my $server = new Continuity(
  path_session => 1,
  port => 18081,
);

my ($handle, $count);

sub main {
  my $request = shift;
  while(1) {
    $request->next;
    my $out = "<pre>\n";

    # The server itself... total size gets bigger and bigger
    $out .= "Server size: " . size($server) . "\n";
    $out .= "Server total size: " . total_size($server) . "\n";

    # Each request has a queue. Maybe that is growing?
    $out .= "Queue size: " . size($request->{queue}) . "\n";
    $out .= "Total Queue size: " . total_size($request->{queue}) . "\n";

    # Statistics about running sessions
    my (@session_ids) = keys %{$server->{mapper}->{continuations}};
    $out .= "Session count: " . (scalar @session_ids) . "\n";

    # Look for event watchers
    my @watchers = Event::all_watchers;
    $out .= "Watchers count: " . (scalar @watchers) . "\n";

    $request->print($out);
  }
}

$server->loop;

