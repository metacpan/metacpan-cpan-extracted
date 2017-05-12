#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Acme::ARUHI::Utils' ) || print "Bail out!\n";
}

ok(defined &Acme::ARUHI::Utils::sum);
is(sum, undef);
is(sum(1), 1);
is(sum(1,2), 3);
is(sum(1,2,3), 6);
is(sum(qw/a 1 2/), 3);
is(sum(qw/a b c/), undef);

done_testing;
