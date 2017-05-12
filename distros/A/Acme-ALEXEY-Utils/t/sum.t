#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
BEGIN {
      use_ok( 'Acme::ALEXEY::Utils' ) || print "Bail out!\n";
}
ok (defined &sum, 'sum is defined');
is (sum(5,2), 7, '5 + 2 = 7');
is (sum(-4,5,15.2), 16.2, '-4 + 5 + 15.2 = 16.2');
eval {sum('fewfew', '-4.623');};
ok ($@, "can't sum nonnumeric arguments");
&done_testing();

