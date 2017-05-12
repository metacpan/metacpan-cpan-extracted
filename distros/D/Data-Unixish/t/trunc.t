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
    func => 'trunc',
    tests => [
        {
            args => {width=>5},
            in   => ['1234', '12345', '123456', ['123456'], {}, undef],
            out  => ['1234', '12345', '12345' , ['123456'], {}, undef],
        },
        {
            name => 'ansi option',
            args => {width=>5, ansi=>1},
            in   => ["12\x1b[31m34\x1b[0m", "12\x1b[31m34\x1b[0m5", "12\x1b[31m34\x1b[0m5\x1b[32m6\x1b[0m"],
            out  => ["12\x1b[31m34\x1b[0m", "12\x1b[31m34\x1b[0m5", "12\x1b[31m34\x1b[0m5\x1b[32m\x1b[0m"],
        },
        {
            name => 'mb option',
            skip => sub { !$zh ? "Chinese locale not supported" : "" },
            args => {width=>7, mb=>1},
            in   => ["我", "我不想回家"],
            out  => ["我", "我不想"],
        },
    ],
);

DONE_TESTING:
done_testing;
