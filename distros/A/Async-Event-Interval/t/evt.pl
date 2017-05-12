use warnings;
use strict;

use Async::Event::Interval;

my $event = Async::Event::Interval->new(
    1,
    sub {
        print "event...\n";
    },
);
$event->start;

sleep 1;
print "main is going to sleep...\n";
sleep 5;

print "done\n";
