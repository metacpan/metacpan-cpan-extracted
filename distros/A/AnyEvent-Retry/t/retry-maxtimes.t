use strict;
use warnings;
use Test::More;
use Test::Exception;

use AnyEvent::Retry;

my $cv = AnyEvent->condvar;
my $r = AnyEvent::Retry->new(
    on_failure => sub { $cv->croak($_[1]) },
    on_success => sub { $cv->send($_[0])  },
    max_tries  => 3,
    interval   => { Fibonacci => { scale => 1/1000 } },
    try        => sub { $_[0]->() }, # never successful (smash with hammer!)
);

$r->start;

throws_ok {
    $cv->recv;
} qr/3/, 'max_tries exceeded after 3';

done_testing;
