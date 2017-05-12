use strict;
use warnings;
use Test::More;
use Test::Output;

use App::Edge;

stdout_is(
    sub { App::Edge->run('share/log5', '-t'); },
    <<_EXPECT_
1: 123
4: xyz
total: 4 lines
_EXPECT_
);

done_testing;