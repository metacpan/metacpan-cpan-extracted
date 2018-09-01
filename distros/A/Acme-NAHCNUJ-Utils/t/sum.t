#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Acme::NAHCNUJ::Utils' ) || print "Bail out!\n";
}

diag( "Testing Acme::NAHCNUJ::Utils $Acme::NAHCNUJ::Utils::VERSION, Perl $], $^X" );

ok(defined &sum, 'Utils::sum is defined');

is(sum(), undef, 'sum() returns undef');
is(sum(undef), undef, 'sum(undef) returns undef');

is(sum(8, 2, 4), 14, 'sum(8, 2, 4) == 14');
is(sum(-2), -2, 'sum(-2) == -2');
is(sum(3.14, -2.71), 0.43, 'sum(3.14, -2.71) == 0.43');
is(sum('hoge', '3.1fuga', 'a0b'), 3.1, 'numbers unlike numeric treat as 0');
is(sum('fuga', 'piyo'), 0, 'return 0 if there is no numeric-like number');

done_testing();
