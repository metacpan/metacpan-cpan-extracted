#!/perl

use 5.010;
use strict;
use utf8;
use warnings;
use Test::Data::Unixish;
use Test::More 0.96;

local $ENV{LANG} = "C";
local $ENV{LC_ALL} = "C";
local $ENV{LC_NUMERIC} = "C";

test_dux_func(
    func => 'num',
    tests => [
        {
            name => 'style=fixed',
            args => {style=>'fixed', decimal_digits=>4},
            in   => [1, -2.3, 45678, "a", [], {}, undef],
            out  => ["1.0000", "-2.3000", "45,678.0000", "a", [], {}, undef],
        },
        {
            name => 'style=scientific',
            args => {style=>'scientific', decimal_digits=>3},
            in   => [1, -2.3, 45678, "a", [], {}, undef],
            test_out => sub {
                my $rout = shift;
                my $v;
                $v = shift @$rout; like($v, qr/\A1\.000e\+0?00\z/, "elem 0");
                $v = shift @$rout; like($v, qr/\A-2\.300e\+0?00\z/, "elem 1");
                $v = shift @$rout; like($v, qr/\A4\.568e\+0?04\z/, "elem 2");
            },
            skip_itemfunc=>1,
        },
        {
            name => 'prefix & suffix',
            args => {prefix=>"p", suffix=>"s"},
            in   => [1, "a", [], {}, undef],
            out  => ["p1s", "a", [], {}, undef],
        },
        {
            name => 'style=kilo',
            args => {style=>"kilo"},
            in   => [0, 1, -2000, "a", [], {}, undef],
            out  => ["0.0", "1.0", "-2.0k", "a", [], {}, undef],
        },
        {
            name => 'style=kibi',
            args => {style=>"kibi"},
            in   => [0, 1, -2000, "a", [], {}, undef],
            out  => ["0.0", "1.0", "-2.0ki", "a", [], {}, undef],
        },
        {
            name => 'thousands_sep',
            args => {thousands_sep=>" "},
            in   => [-20000],
            out  => ["-20 000"],
        },
        {
            name => 'style=percent',
            args => {style=>"percent"},
            in   => [0, 1, -0.21, "a", [], {}, undef],
            out  => ["0.00%", "100.00%", "-21.00%", "a", [], {}, undef],
        },
    ],
);

done_testing;
