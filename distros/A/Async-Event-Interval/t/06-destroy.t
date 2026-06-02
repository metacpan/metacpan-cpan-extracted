use strict;
use warnings;

use lib 't/lib';
use TestHelper;
use Test::More;

use Async::Event::Interval;

my $mod = 'Async::Event::Interval';

{
    my $e = $mod->new(0, sub {});
}

is
    eval {my $e = $mod->new(0, sub {}); 1; },
    1,
    "%events doesn't get destroyed until END block ok";