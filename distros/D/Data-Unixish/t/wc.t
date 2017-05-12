#!/perl

use 5.010;
use strict;
use utf8;
use warnings;
use Test::Data::Unixish;
use Test::More 0.98;

require POSIX;
my $zh = POSIX::setlocale(&POSIX::LC_ALL, "zh_CN.utf8");

test_dux_func(
    func  => 'wc',
    tests => [
        {
            in   => ["one\n", "two three\n", "four\nfive\n", undef, []],
            args => {},
            out  => ["4\t5\t24"],
        },
    ],
);

test_dux_func(
    func  => 'wc',
    skip  => sub { !$zh ? "Chinese locale not supported" : "" },
    tests => [
        {
            in   => ["王力宏\n", "梅艳芳\n", undef, []],
            args => {chars=>1, bytes=>1, max_line_length=>1},
            out  => ["8\t20\t9"],
        },
    ],
);

done_testing;
