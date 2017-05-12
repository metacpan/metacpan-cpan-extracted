use warnings;
use strict;

use Bit::Manip qw(:all);
use Test::More;

{
    for (0..1023){
        is bit_bin($_), sprintf("%b", $_), "$_ binary ok";
    }
}
done_testing();
