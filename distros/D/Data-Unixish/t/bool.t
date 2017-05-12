#!/perl

use 5.010;
use strict;
use utf8;
use warnings;
use Test::Data::Unixish;
use Test::More 0.96;

test_dux_func(
    func => 'bool',
    tests => [
        {
            name => 'perl notion, style',
            args => {style=>'y_n'},
            in   => [1, " ", "", 0, [], {}, undef],
            out  => ['y', 'y', 'n', 'n', 'y', 'y', undef],
        },
        {
            name => 'n1 notion',
            args => {notion=>'n1'},
            in   => [1, " ", "", 0, [], {}, [0], {a=>0}, undef],
            out  => [1, 1, 0, 0, 0, 0, 1, 1, undef],
        },
        {
            name => 'true_char & false_char',
            args => {true_char => 'BETUL', false_char => 'SALAH'},
            in   => [1, 0, undef],
            out  => ["BETUL", "SALAH", undef],
        },
    ],
);

done_testing;
