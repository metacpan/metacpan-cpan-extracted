#!/usr/bin/perl -w
use warnings;
use strict;
use lib qw(lib t);
use Benchmark;

use Ambrosia::core::Nil;

my $sum = 0;
my $str = '';
timethese(100000, {
        'new'    => sub {
            my $my_nil = new Ambrosia::core::Nil;
        },

        'as_string'  => sub {
            $str .= new Ambrosia::core::Nil;
        },

        'as_integer'    => sub {
            $sum += new Ambrosia::core::Nil;
        },

        'as_sub 2'    => sub {
            Ambrosia::core::Nil->new()->()->();
        },

        'as_method'    => sub {
            Ambrosia::core::Nil->new()->a();
        },
});

