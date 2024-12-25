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
    a_index_of(
        $myFish_a1,
        "clown"
    ),
    1,
    'a_index_of.'
);

##
my $myFish_a2 = [ "angel", "clown", "mandarin", "clown", "sturgeon" ];
is_deeply(
    a_index_of(
        $myFish_a2,
        "clown", 2
    ),
    3,
    'a_index_of.'
);

##
my $myFish_a3 = [ "angel", "clown", "mandarin", "clown", "sturgeon" ];
is_deeply(
    a_index_of(
        $myFish_a3,
        "clown1"
    ),
    -1,
    'a_index_of.'
);


####################
####################
####################
##
my $myFish_1 = [ "angel", "clown", "mandarin", "clown", "sturgeon" ];
is_deeply(
    a_last_index_of(
        $myFish_1,
        "clown"
    ),
    3,
    'a_last_index_of.'
);

##
my $myFish_2 = [ "angel", "clown", "mandarin", "clown", "sturgeon" ];
is_deeply(
    a_last_index_of(
        $myFish_2,
        "clown", 2
    ),
    1,
    'a_last_index_of.'
);

##
my $myFish_3 = [ "angel", "clown", "mandarin", "clown", "sturgeon" ];
is_deeply(
    a_last_index_of(
        $myFish_3,
        "clown1"
    ),
    -1,
    'a_last_index_of.'
);

############
done_testing();
