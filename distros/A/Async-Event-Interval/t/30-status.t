use strict;
use warnings;

use Async::Event::Interval;
use Test::More;

my $mod = 'Async::Event::Interval';

my $e = $mod->new(1, \&perform, 10);

{
    # warn on start() if started

    is $e->status, 0, "before starting, status() is zero";
    $e->start;
    is $e->status > 0, 1, "status() ok if started";
    is $e->status, $e->_pid, "status() is the same as the event PID";
    $e->stop;
    is $e->status, 0, "status() ok if not started";
}

sub perform {
    return;
}

done_testing();
