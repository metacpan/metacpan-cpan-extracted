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

warn "Segs after: " . `ipcs -m | wc -l` . "\n" if $ENV{PRINT_SEGS};

done_testing();
