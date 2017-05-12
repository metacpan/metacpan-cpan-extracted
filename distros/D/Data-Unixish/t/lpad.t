#!/perl

use 5.010;
use strict;
use utf8;
use warnings;
use Test::Data::Unixish;
use Test::More 0.96;

require POSIX;
my $zh = POSIX::setlocale(&POSIX::LC_ALL, "zh_CN.utf8");

test_dux_func(
    func => 'lpad',
    tests => [
        {
            args => {width=>5},
            in   => ['123'  , '12345', '123456', ['1'], {}, undef],
            out  => ['  123', '12345', '123456', ['1'], {}, undef],
        },
        {
            name => 'truncate',
            args => {width=>5, trunc=>1},
            in   => ['123'  , '12345', '123456', ['123456'], {}, undef],
            out  => ['  123', '12345', '12345' , ['123456'], {}, undef],
        },
        # TODO: test --ansi
        # TODO: test --mb
        # TODO: test --char
    ],
);

DONE_TESTING:
done_testing;
