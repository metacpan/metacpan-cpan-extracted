#!/usr/bin/perl

use strict;
use lib '../lib';
use Continuity;
use Coro::AnyEvent;

use Coro::Debug;
our $coro_debug_server = new_unix_server Coro::Debug "/tmp/corodebug";

$| = 1;

my $reap_watcher;
sub reaper {
  $reap_watcher = AnyEvent->timer(
    interval => 1,
    cb => sub {
      print "Reap event!\n";
    }
  );
}
# reaper();

sub main {
  my $request = shift;

  print "AnyEvent model: " . $AnyEvent::MODEL . "\n";

  foreach my $n (1..10) {
    print STDERR "count: $n\n";
    $request->print("count: $n\n");
    # sleep 1;
    Coro::AnyEvent::sleep 1;
  }
}

my $server = Continuity->new(
  query_session => 'sid',
  cookie_session => 0,
  debug_level => 3,
  port => 5000,
);

$server->loop;
