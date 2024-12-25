use strict;
use warnings;

use CommonsLang;
use Test::More;

####################
####################
####################
##
my $myFish_a1 = [ "angel", "clown", "mandarin", "clown", "sturgeon" ];
is_deeply(
    a_find(
        $myFish_a1,
        sub {
            my ($itm, $idx) = @_;
            return $itm eq "clown";
        }
    ),
    "clown",
    'a_find.'
);

##
my $myFish_a2 = [ "angel", "clown", "mandarin", "sturgeon" ];
is_deeply(
    a_find(
        $myFish_a2,
        sub {
            my ($itm, $idx) = @_;
            return $itm eq "clown1";
        }
    ),
    undef,
    'a_find.'
);

####################
####################
####################
##
my $myFish_b1 = [ "angel", "clown", "mandarin", "clown", "sturgeon" ];
is_deeply(
    a_find_last(
        $myFish_b1,
        sub {
            my ($itm, $idx) = @_;
            return $itm eq "clown";
        }
    ),
    "clown",
    'a_find_last.'
);

##
my $myFish_b2 = [ "angel", "clown", "mandarin", "sturgeon" ];
is_deeply(
    a_find_last(
        $myFish_b2,
        sub {
            my ($itm, $idx) = @_;
            return $itm eq "clown1";
        }
    ),
    undef,
    'a_find_last.'
);

############
done_testing();
