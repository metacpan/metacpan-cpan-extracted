use strict;
use warnings;

use CommonsLang;
use Test::More;

####################
####################
####################
##
my $myFish_a1 = [ "angel", "clown", "mandarin", "sturgeon" ];
is_deeply(
    a_find_index(
        $myFish_a1,
        sub {
            my ($itm, $idx) = @_;
            return $itm eq "clown";
        }
    ),
    1,
    'a_find_index.'
);

##
my $myFish_a2 = [ "angel", "clown", "mandarin", "sturgeon" ];
is_deeply(
    a_find_index(
        $myFish_a2,
        sub {
            my ($itm, $idx) = @_;
            return $itm eq "clown1";
        }
    ),
    -1,
    'a_find_index.'
);


####################
####################
####################
##
my $myFish_b1 = [ "angel", "clown", "mandarin", "clown", "sturgeon" ];
is_deeply(
    a_find_last_index(
        $myFish_b1,
        sub {
            my ($itm, $idx) = @_;
            return $itm eq "clown";
        }
    ),
    3,
    'a_find_last_index.'
);

##
my $myFish_b2 = [ "angel", "clown", "mandarin", "sturgeon" ];
is_deeply(
    a_find_last_index(
        $myFish_b2,
        sub {
            my ($itm, $idx) = @_;
            return $itm eq "clown1";
        }
    ),
    -1,
    'a_find_last_index.'
);


############
done_testing();
