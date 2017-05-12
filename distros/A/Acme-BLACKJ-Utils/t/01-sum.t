#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
    use_ok( 'Acme::BLACKJ::Utils' ) || print "Bail out!\n";
}

diag( "Testing Acme::BLACKJ::Utils $Acme::BLACKJ::Utils::VERSION, Perl $], $^X" );

ok( defined &Acme::BLACKJ::Utils::sum, 'Acme::BLACKJ::Utils::sum is defined' );

ok( &Acme::BLACKJ::Utils::sum(1, 1) eq 2, 'Sum of 1 + 1 should equal 2');
ok( &Acme::BLACKJ::Utils::sum(1, 2) ne 2, 'Sum of 1 + 2 should not equal 2');
ok( &Acme::BLACKJ::Utils::sum(1, 3) gt 3, 'Sum of 1 + 3 should be > 3');
ok( &Acme::BLACKJ::Utils::sum(1, 4) lt 6, 'Sum of 1 + 4 should be < 6');
ok( &Acme::BLACKJ::Utils::sum(0, 0) eq 0, 'Sum of 0 + 0 should equal 0');
ok( &Acme::BLACKJ::Utils::sum(1, 10) gt 10, 'Sum of 1 + 10 should be > 10');
ok( &Acme::BLACKJ::Utils::sum('1', 10) gt 10, 'Sum of 1 string and number should be > 10');
ok( &Acme::BLACKJ::Utils::sum('1', '10') gt 10, 'Sum of two strings should be > 10');

done_testing();
