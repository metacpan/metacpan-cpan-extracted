use Test2::Bundle::Extended;
use AnyEvent;
use Argon::Async;

my $cv = AnyEvent->condvar;

tie my $async, 'Argon::Async', $cv;

$cv->send('foo');

is $async, 'foo', 'basics';

done_testing;
