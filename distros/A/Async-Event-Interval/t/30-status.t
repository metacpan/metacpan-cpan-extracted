use strict;
use warnings;

use Test::More;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a valid CI testing platform...";
    }
    warn "Segs before: " . `ipcs -m | wc -l` . "\n" if $ENV{PRINT_SEGS};
}

use Async::Event::Interval;

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

warn "Segs after: " . `ipcs -m | wc -l` . "\n" if $ENV{PRINT_SEGS};

done_testing();
