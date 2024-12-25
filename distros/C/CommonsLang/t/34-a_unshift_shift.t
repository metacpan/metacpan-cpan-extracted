use strict;
use warnings;

use CommonsLang;
use Test::More;

####################
####################
####################
##
my $myFish_a1 = [ "angel", "clown", "mandarin", "sturgeon" ];
is(a_unshift($myFish_a1), 4, 'a_unshift.');
is_deeply($myFish_a1, [ "angel", "clown", "mandarin", "sturgeon" ], 'a_unshift.');

##
my $myFish_a2 = [ "angel", "clown", "mandarin", "sturgeon" ];
is(a_unshift($myFish_a2, "a"), 5, 'a_unshift.');
is_deeply($myFish_a2, [ "a", "angel", "clown", "mandarin", "sturgeon" ], 'a_unshift.');

##
my $myFish_a3       = [ "angel", "clown", "mandarin", "sturgeon" ];
my $tobe_unshift_a3 = [ "a",     "b" ];
is(a_unshift($myFish_a3, @$tobe_unshift_a3), 6, 'a_unshift.');
is_deeply($myFish_a3, [ "a", "b", "angel", "clown", "mandarin", "sturgeon" ], 'a_unshift.');

####################
####################
####################
##
my $myFish_b1 = [ "angel", "clown", "mandarin", "sturgeon" ];
is(a_shift($myFish_b1), "angel", 'a_shift.');
is_deeply($myFish_b1, [ "clown", "mandarin", "sturgeon" ], 'a_shift.');


############
done_testing();
