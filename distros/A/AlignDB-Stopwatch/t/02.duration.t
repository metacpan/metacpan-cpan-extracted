use strict;
use warnings;
use Test::More;

use AlignDB::Stopwatch;

my $stopwatch = AlignDB::Stopwatch->new;

is($stopwatch->duration_now, '0 seconds');

sleep 1;
is($stopwatch->duration_now, '1 second');

sleep 1;
is($stopwatch->duration_now, '2 seconds');

$stopwatch->start_time(time - 3600);
is($stopwatch->duration_now, '1 hour');

done_testing(4);
