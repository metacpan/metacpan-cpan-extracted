#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Borang::HTML qw(gen_html_form);

my $res = gen_html_form(
    meta => {
        v => 1.1,

        # arguments will become form widgets/fields. the order of fields will
        # follow the argument's 'pos' property, or asciibetical if 'pos' is
        # undefined.

        args => {

            # without caption or summary, argument name will be used as form
            # field caption
            num1 => {
                schema => 'int',
                pos => 0,
            },

            # field size can be guessed from schema (max, min, xmax, xmin,
            # between, xbetween, or default value). in num2, field size is
            # determined as magnitude(99) = 2 but rounded up to 3. maxlength is
            # also capped at 3.
            num2 => {
                schema => ['int', between=>[1,99]],
                pos => 1,
            },

            # in num3, field size is determined as magnitude(-1e10) = 10.
            # maxlength is 10 + 12 (to allow for negative sign, decimal sign,
            # and some digits after decimals) = 22.
            num3 => {
                schema => ['float', max=>-1e10],
                pos => 2,
            },

            # without caption, summary will be used as form field caption.
            text1 => {
                summary => 'A text field',
                pos => 3,
            },

            # field size can be guessed from schema (max_len, min_len,
            # len_between, or default value). in text2, maxlength will be 100
            # (from max_len property), but the field size will be 80 instead of
            # 100 (currently hardcoded limit to avoid field that is too wide)
            text2 => {
                summary => 'A longer text field (hint from schema)',
                caption => 'A longer text field',
                schema  => ['str*', max_len=>100],
                pos => 4,
            },

            password1 => {
                summary => 'A password field',
                # even though we don't specify explicitly, borang can guess by
                # looking at the argument name
                #is_password => 1,
                schema => 'str*',
                pos => 5,
            },
        },
    },
);

print $res;
