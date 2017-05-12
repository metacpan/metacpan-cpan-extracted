#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Borang::HTML qw(gen_html_form);
use Locale::Tie '$LANG';

# Borang supports translation. it will use caption/summary from the appropriate
# language, if available.

my $res = gen_html_form(
    meta => {
        v => 1.1,
        args => {

            num1 => {
                schema => 'int',
                summary => 'English summary of num1',
                'summary(id_ID)' => 'Ringkasan num1 dalam bahasa Indonesia',
            },

            text1 => {
                schema => 'str*',
                caption => 'English caption of text1',
                'caption(id_ID)' => 'Label text1 dalam bahasa Indonesia',
            },

        },
    },
    lang => 'id_ID',
);

print $res;
