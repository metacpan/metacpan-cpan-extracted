use strict;
use warnings;
use Test::More;
use Test::Output;

use App::Edge;

stdout_is(
    sub { App::Edge->run('share/log1'); },
    ""
);

stdout_is(
    sub { App::Edge->run('share/log2'); },
    "1: 123\n"
);

stdout_is(
    sub { App::Edge->run('share/log3'); },
    "1: 123\n2: abc\n"
);

stdout_is(
    sub { App::Edge->run('share/log3', '--grep', 'abc'); },
    "1: abc\n"
);

stdout_is(
    sub { App::Edge->run('share/log3', '--grepv', 'abc'); },
    "1: 123\n"
);

stdout_is(
    sub { App::Edge->run('share/log4'); },
    "1: 123\n3: xyz\n"
);

stdout_is(
    sub { App::Edge->run('share/log4', '--grep', 'abc'); },
    "1: abc\n"
);

stdout_is(
    sub { App::Edge->run('share/log4', '--grep', 'x', '--grep', 'z'); },
    "1: xyz\n"
);

stdout_is(
    sub { App::Edge->run('share/log4', '--grepv', 'abc'); },
    "1: 123\n2: xyz\n"
);

stdout_is(
    sub { App::Edge->run('share/log4', '--grepv', 'ab', '--grepv', '23'); },
    "1: xyz\n"
);

stdout_is(
    sub { App::Edge->run('share/log5', '--grep', 'a', '--grepv', '23'); },
    "1: aaa\n2: abc\n"
);

stdout_is(
    sub { App::Edge->run('share/log2', 'share/log3'); },
    <<_EXPECT_
==> share/log2 <==
1: 123
==> share/log3 <==
1: 123
2: abc
_EXPECT_
);

stdout_is(
    sub { App::Edge->run('share/log2', 'share/log3', '--grep', '1'); },
    <<_EXPECT_
==> share/log2 <==
1: 123
==> share/log3 <==
1: 123
_EXPECT_
);

stdout_is(
    sub { App::Edge->run('share/log2', 'share/log3', '--grepv', '1'); },
    <<_EXPECT_
==> share/log2 <==
==> share/log3 <==
1: abc
_EXPECT_
);

done_testing;
