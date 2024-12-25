use strict;
use warnings;

use CommonsLang;
use Test::More;

##
my $myFish_1 = [ "angel", "clown", "mandarin", "sturgeon" ];
is_deeply(
    a_filter(
        $myFish_1,
        sub {
            my ($itm, $idx) = @_;
            return index($itm, "l") != -1;
        }
    ),
    [ "angel", "clown" ],
    'a_filter.'
);

##
my $myFish_2 = [ "angel", "clown", "mandarin", "sturgeon" ];
is_deeply(
    a_filter(
        $myFish_2,
        sub {
            my ($itm, $idx) = @_;
            return index($itm, "vvv") != -1;
        }
    ),
    [],
    'a_filter.'
);

############
done_testing();
