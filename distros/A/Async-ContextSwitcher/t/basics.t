use strict; use warnings;

use Test::More;

use_ok('Async::ContextSwitcher');
use Async::ContextSwitcher qw(context cb_w_context);

use AnyEvent;
my $cv = AnyEvent->condvar;

my $how_many = 10;

for my $i (1 .. $how_many) {
    Async::ContextSwitcher->new( test => $i );

    my $w;
    $w = AnyEvent->timer( after => rand()*0.1, cb => cb_w_context {
        $w = undef;

        my $cb = cb_w_context {
            is context->{test}, $i, "good $i";
            $cv->send if --$how_many == 0;
        };
        AnyEvent::postpone { $cb->() };
    });
}
$cv->recv;

done_testing;
