use strict;
use warnings;

use Test::More 'no_plan';

use_ok 'Benchmark::Stopwatch';

my $sw = Benchmark::Stopwatch->new;
isa_ok $sw, 'Benchmark::Stopwatch';

can_ok $sw, 'start';
can_ok $sw, 'lap';
can_ok $sw, 'stop';
can_ok $sw, 'summary';
can_ok $sw, 'time';

