use strict;
use warnings;

use lib 't/lib';
use TestHelper;
use IPC::Shareable;
use Mock::Sub;
use Test::More;

use Async::Event::Interval;

my $mod = 'Async::Event::Interval';

# Proper cleanup
{
    my ($keys, $register);

    {
        $register = IPC::Shareable::global_register;
        $keys = keys %$register;
        is $keys, 1, "IPC::Shareable shows one entry before event creation ok";

        my $e = $mod->new(0, sub {});

        $register = IPC::Shareable::global_register;
        $keys = keys %$register;
        is $keys, 2, "IPC::Shareable shows two entries after event creation ok";
    }

    # Force the END block for cleanup
    Async::Event::Interval::_end();

    $register = IPC::Shareable::global_register;
    $keys = keys %$register;
    is $keys, 0, "IPC::Shareable shows no entries after object out of scope ok";
}
