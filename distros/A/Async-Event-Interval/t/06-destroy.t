use strict;
use warnings;

use Data::Dumper;
use Test::More;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a valid CI testing platform...";
    }
    warn "Segs before: " . `ipcs -m | wc -l` . "\n" if $ENV{PRINT_SEGS};
}

use Async::Event::Interval;

my $mod = 'Async::Event::Interval';

{
    my $e = $mod->new(0, sub {});
}

is
    eval {my $e = $mod->new(0, sub {}); 1; },
    1,
    "%events doesn't get destroyed until END block ok";

warn "Segs after: " . `ipcs -m | wc -l` . "\n" if $ENV{PRINT_SEGS};

done_testing();