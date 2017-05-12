#!perl -w

use strict;
use warnings;
use Test::More tests => 6;

use Data::Dump::Perl6 qw/dump_perl6/;

if ("abc" =~ /(.+)/) {
    is(dump_perl6($1), '"abc"');
    is(dump_perl6(\$1), '"abc"');
    is(dump_perl6([$1]), '["abc"]');
}

if ("123" =~ /(.+)/) {
    is(dump_perl6($1), "123");
    is(dump_perl6(\$1), '123');
    is(dump_perl6([$1]), '[123]');
}
