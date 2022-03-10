use strict;
use warnings;

use Async::Event::Interval;
use Data::Dumper;
use Test::More;

if (! $ENV{CI_TESTING}) {
    plan skip_all => "Not on a valid CI testing platform..."
}

my $mod = 'Async::Event::Interval';

{
    my $e = $mod->new(0, sub {});
}

is
    eval {my $e = $mod->new(0, sub {}); 1; },
    1,
    "%events doesn't get destroyed until END block ok";

done_testing();