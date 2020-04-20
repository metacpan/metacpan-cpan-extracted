use strict;
use warnings;
use Test::More qw(no_plan);

ok(eval { require Async::Methods; 1 }, 'loaded ok');
