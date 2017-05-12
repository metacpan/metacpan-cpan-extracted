#!perl

use 5.010001;
use strict;
use warnings;

use Test::Data::Sah::Format;
use Test::Exception;
use Test::More 0.98;
#use Test::Needs;

subtest boolstr => sub {
    test_format(
        name   => 'opt:style=yes_no',
        format => 'boolstr',
        data   => [1, 0, undef],
        fdata  => ["yes", "no", undef],
    );
    test_format(
        name   => 'opt:style=Y_N',
        format => 'boolstr',
        formatter_args => {style=>'Y_N'},
        data   => [1, 0, undef],
        fdata  => ["Y", "N", undef],
    );
    test_format(
        name   => 'opt:style=true_false',
        format => 'boolstr',
        formatter_args => {style=>'true_false'},
        data   => [1, 0, undef],
        fdata  => ["true", "false", undef],
    );
    test_format(
        name   => 'opt:style=T_F',
        format => 'boolstr',
        formatter_args => {style=>'T_F'},
        data   => [1, 0, undef],
        fdata  => ["T", "F", undef],
    );
    test_format(
        name   => 'opt:style=1_0',
        format => 'boolstr',
        formatter_args => {style=>'1_0'},
        data   => [1, 0, undef],
        fdata  => ["1", "0", undef],
    );
    test_format(
        name   => 'opt:style=on_off',
        format => 'boolstr',
        formatter_args => {style=>'on_off'},
        data   => [1, 0, undef],
        fdata  => ["on", "off", undef],
    );
    test_format(
        name   => 'opt:true_str & false_str',
        format => 'boolstr',
        formatter_args => {true_str=>'ya', false_str=>'tidak'},
        data   => [1, 0, undef],
        fdata  => ["ya", "tidak", undef],
    );
};

done_testing;
