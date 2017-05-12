#!/usr/bin/perl

use Test::More tests => 8;
use Test::Exception;

use lib qw(lib t);

BEGIN {
    use_ok( 'Ambrosia::core::Nil' ); #test #1
}
require_ok( 'Ambrosia::core::Nil' ); #test #2

my $my_nil = new_ok Ambrosia::core::Nil => [a => 1, b => 2, c => 3]; #test #3

cmp_ok($my_nil->a, '==', 0, 'Integer 1.'); #test #4
$my_nil->a(321);
cmp_ok($my_nil->a, '==', 0, 'Integer 2.'); #test #5

cmp_ok($my_nil->(), '==', 0, 'Sub 1.'); #test #6

cmp_ok($my_nil->()->(), '==', 0, 'Sub 2.'); #test #7

cmp_ok($my_nil->()->()->(), '==', 0, 'Sub 3.'); #test #8
