use strict;
use warnings;

use Data::Dumper;
use Mock::Sub;
use Test::More;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a valid CI testing platform...";
    }
    warn "Segs before: " . `ipcs -m | wc -l` . "\n" if $ENV{PRINT_SEGS};
}

use Async::Event::Interval;
use IPC::Shareable;

my $mod = 'Async::Event::Interval';

# No call to IPC::Shareable::clean_up_protected()
{
    my ($keys, $register, $protect_lock, $sub);
    my $m = Mock::Sub->new;

    {
        $register = IPC::Shareable::global_register;
        $keys = keys %$register;
        is $keys, 1, "IPC::Shareable shows one entry before event creation ok";

        my $e = $mod->new(0, sub {});
        $protect_lock = $e->_shm_lock;

        $register = IPC::Shareable::global_register;
        $keys = keys %$register;
        is $keys, 2, "IPC::Shareable shows two entries after event creation ok";

        $sub = $m->mock('Async::Event::Interval::_shm_lock');
        $sub->return_value(999999);

        is $e->_shm_lock, 999999, "Mock::Sub has properly mocked _shm_lock()";
    }

    $register = IPC::Shareable::global_register;
    $keys = keys %$register;
    is $keys, 2, "The \%events hash shm segment nor its child wasn't removed ok";

    $sub->unmock;

    # Force the END block for cleanup
    Async::Event::Interval::_end();

    $register = IPC::Shareable::global_register;
    $keys = keys %$register;
    IPC::Shareable::clean_up_protected($protect_lock);
    is $keys, 0, "IPC::Shareable shows no entries in the register after cleanup";
}

warn "Segs after: " . `ipcs -m | wc -l` . "\n" if $ENV{PRINT_SEGS};

done_testing();