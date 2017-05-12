use strict;
use warnings;
use Test::More;

use AlignDB::Stopwatch;

my $stopwatch = AlignDB::Stopwatch->new;

is(ref $stopwatch, 'AlignDB::Stopwatch');

ok($stopwatch->start_time =~ /^\d+$/);
ok($stopwatch->uuid =~ /^[\w-]+$/);

$stopwatch->start_time(time);
like($stopwatch->_time, qr{^Current.+\n$});

$stopwatch->start_time(time);
like($stopwatch->_time("Hello"), qr{^Hello.+\n$});

done_testing(5);
