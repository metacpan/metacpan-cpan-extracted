use strict;
use warnings;

use CommonsLang;
use Test::More;

####################
####################
####################
##
my $myFish_a1 = [ 12, 5, 8, 130, 44 ];
is(
    a_every(
        $myFish_a1,
        sub {
            my ($itm, $idx) = @_;
            return $itm >= 10;
        }
    ),
    0,
    'a_every.'
  );

##
my $myFish_a2 = [ 12, 54, 18, 130, 44 ];
is(
    a_every(
        $myFish_a2,
        sub {
            my ($itm, $idx) = @_;
            return $itm >= 10;
        }
    ),
    1,
    'a_every.'
  );

####################
####################
####################
##
my $myFish_b1 = [ 2, 5, 8, 1, 4 ];
is(
    a_some(
        $myFish_b1,
        sub {
            my ($itm, $idx) = @_;
            return $itm >= 10;
        }
    ),
    0,
    'a_some.'
  );

##
my $myFish_b2 = [ 2, 5, 18, 1, 4 ];
is(
    a_some(
        $myFish_b2,
        sub {
            my ($itm, $idx) = @_;
            return $itm >= 10;
        }
    ),
    1,
    'a_some.'
  );

############
done_testing();
