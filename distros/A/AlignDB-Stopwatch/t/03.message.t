use strict;
use warnings;
use Test::More;
use Test::Output;

use AlignDB::Stopwatch;

my $stopwatch = AlignDB::Stopwatch->new;

is( $stopwatch->_message, "\n" );

stdout_is(
    sub { $stopwatch->block_message },
    $stopwatch->_empty_line . $stopwatch->_prompt . $stopwatch->_message . $stopwatch->_empty_line
);

stdout_is(
    sub { $stopwatch->block_message },
    "\n==> \n\n"
);

stdout_is(
    sub { $stopwatch->block_message("Hello") },
    "\n==> Hello\n\n"
);

$stopwatch->start_time(time);
stdout_is(
    sub { $stopwatch->block_message("Hello", 1) },
    "\n==> Hello\n==> Runtime 0 seconds.\n\n"
);

done_testing(5);
