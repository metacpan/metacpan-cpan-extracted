use strict;
use warnings;

use CommonsLang;
use Test::More;

##
my $myFish_1 = [ "angel", "clown", "mandarin", "clown", "sturgeon" ];
is_deeply(
    a_map(
        $myFish_1,
        sub {
            my ($itm, $idx) = @_;
            return $itm . "_" . $idx;
        }
    ),
    [ "angel_0", "clown_1", "mandarin_2", "clown_3", "sturgeon_4" ],
    'a_map.'
);

############
done_testing();
