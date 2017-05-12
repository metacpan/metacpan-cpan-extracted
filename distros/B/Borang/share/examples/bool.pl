#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Borang::HTML qw(gen_html_form);

my $res = gen_html_form(
    meta => {
        v => 1.1,

        args => {

            bool1 => {
                schema => 'bool',
            },

            # default on
            bool2 => {
                schema => 'bool',
                default => 1,
            },

            # default off
            bool3 => {
                schema => 'bool',
                default => 0,
            },

            # you can override which widget to use by using the 'form.widget'
            # attribute.
            bool4 => {
                schema => 'bool',
                'form.widget' => 'Text',
            },

        },
    },
);

print $res;
