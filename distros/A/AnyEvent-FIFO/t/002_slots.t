use strict;
use Test::More (tests => 121);
use AnyEvent;

use_ok "AnyEvent::FIFO";

my $q = AnyEvent::FIFO->new();

foreach my $group ('a'..'c') {
    my $expected = 1;
    foreach my $i (1..10) {
        $q->push( $group, sub {
            my ($guard, @args) = @_;
            is( $args[0], $i, "arg is $i" );
            is( $i, $expected++, "slot $group, $i-th execution" );
	    is( $q->active($group), 1, "1 task is running" );
	    is( $q->waiting($group), 10 - $i, "$i tasks is waiting" );
        }, $i );
    }
}

$q->cv->recv;
