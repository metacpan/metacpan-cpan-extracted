use strict;
use warnings;

use Async::Event::Interval;
use Data::Dumper;
use IPC::Shareable;
use Mock::Sub;
use Test::More;

my $mod = 'Async::Event::Interval';

# Direct cleanup
{
    my ($keys, $register);

    {
        $register = IPC::Shareable::global_register;
        $keys = keys %$register;
        is $keys, 1, "IPC::Shareable shows one entry before shared hash creation";

        tie my %h, 'IPC::Shareable', {key => 51454215, create => 1, destroy => 1};
        $register = IPC::Shareable::global_register;
        $keys = keys %$register;
        is $keys, 2, "IPC::Shareable shows two entry before event creation ok";

        my $e = $mod->new(0, sub {});
        my $f = $mod->new(0, sub {});

        $register = IPC::Shareable::global_register;
        $keys = keys %$register;
        is $keys, 4, "IPC::Shareable shows three entries after event creation ok";

        IPC::Shareable::clean_up_all;

        $register = IPC::Shareable::global_register;
        $keys = keys %$register;
        is $keys, 3, "Calling IPC::Shareable::clean_up_all leaves our \%event hash alone";
    }

    # Force the END block for cleanup
    Async::Event::Interval::_end();

    $register = IPC::Shareable::global_register;
    $keys = keys %$register;
    is $keys, 0, "IPC::Shareable shows no entries after object out of scope ok";
}

done_testing();
