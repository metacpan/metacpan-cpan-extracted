use strict;
use warnings;

use lib 't/lib';
use TestHelper;
use IPC::Shareable;
use Test::More;

use Async::Event::Interval;

my $mod = 'Async::Event::Interval';

{
    tie my $scalar, 'IPC::Shareable', { destroy => 1 };

    $scalar = -1;

    is $scalar, -1, "shared var has original value before event start" ;

    my $e = $mod->new(0.2, \&perform);
    $e->start;
    select(undef, undef, undef, 0.4);
    $e->stop;

    is $scalar, 99, "shared var has updated value after event start" ;

    sub perform {
        $scalar = 99;
    }
}
