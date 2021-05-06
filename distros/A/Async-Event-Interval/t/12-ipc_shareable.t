use strict;
use warnings;

use Async::Event::Interval;
use Test::More;

require IPC::Shareable;
import IPC::Shareable;
use Data::Dumper;

# duplicate key
# scalar values only
# multiple scalars per event
# class or object based?

my $mod = 'Async::Event::Interval';

tie my $scalar, 'IPC::Shareable', undef;

$scalar = -1;

is $scalar, -1, "shared var has original value before event start" ;

my $e = $mod->new(1, \&perform);
$e->start;
sleep 1;
$e->stop;

is $scalar, 99, "shared var has updated value after event start" ;

sub perform {
    $scalar = 99;
}

done_testing();
