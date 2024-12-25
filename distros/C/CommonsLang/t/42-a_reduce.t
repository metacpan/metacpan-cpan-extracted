use strict;
use warnings;

use CommonsLang;
use Test::More;

##
my $myFish_1 = [ "angel", "clown", "mandarin", "clown", "sturgeon" ];
is(
    a_reduce(
        $myFish_1,
        sub {
            my ($ret, $itm, $idx) = @_;
            $ret = $ret + 1;
            return $ret;
        },
        10
    ),
    15,
    'a_reduce.'
  );

############
done_testing();
