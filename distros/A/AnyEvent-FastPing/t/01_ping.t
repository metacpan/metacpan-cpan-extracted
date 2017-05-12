BEGIN { $> and do { print "1..0 # skipped: will only run ping tests as root\n"; exit } }

print "1..4\n";

use strict;

use AnyEvent;
use AnyEvent::FastPing;

my $done = AnyEvent->condvar;

print "ok 1\n";

my $pinger = new AnyEvent::FastPing;

$pinger->max_rtt (0.01);
$pinger->add_range (v127.0.0.1, v127.0.0.255);
$pinger->add_range (v127.0.1.1, v127.0.1.005);

$pinger->on_idle (sub {
   print "ok 3\n";
   $done->();
});

print "ok 2\n";

$pinger->start;
$done->wait;

print "ok 4\n";
