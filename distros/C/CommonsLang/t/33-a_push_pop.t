use strict;
use warnings;

use CommonsLang;
use Test::More;

####################
####################
####################
##
my $sports_a1 = [ "soccer", "baseball" ];
my $total_a1  = a_push($sports_a1, "football", "swimming");
is($total_a1,               4,                                   'a_push.');
is(a_join($sports_a1, ","), "soccer,baseball,football,swimming", 'a_push.');
##
my $sports_a2 = [ "soccer", "baseball" ];
my $total_a2  = a_push($sports_a2, [ "football", "swimming" ]);
is($total_a2, 3, 'a_push.');
is(
    a_join([ $sports_a2->[0], $sports_a2->[1] ], ",") . ",[" . a_join($sports_a2->[2], ",") . "]",
    "soccer,baseball,[football,swimming]", 'a_push.'
  );

####################
####################
####################
##
my $sports_b1 = [ "soccer", "baseball" ];

is(a_pop($sports_b1),  "baseball", 'a_pop.');
is(scalar @$sports_b1, 1,          'a_pop.');

is(a_pop($sports_b1),  "soccer", 'a_pop.');
is(scalar @$sports_b1, 0,        'a_pop.');
## empty
is(a_pop($sports_b1),  undef, 'a_pop.');
is(scalar @$sports_b1, 0,     'a_pop.');


############
done_testing();
