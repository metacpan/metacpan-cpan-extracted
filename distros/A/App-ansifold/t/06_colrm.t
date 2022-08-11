use v5.14;
use warnings;
use utf8;

use Data::Dumper;
use Test::More;

use Text::ParseWords qw(shellwords);

BEGIN {
    $App::ansifold::DEFAULT_SEPARATE = "";
    $App::ansifold::DEFAULT_COLRM = 1;
}

use lib '.';
use t::Util;

##
## colrm
##

test
    option => "4",
    stdin  => "1234567890",
    expect => "123";

test
    option => "4 7",
    stdin  => "1234567890",
    expect => "123890";

done_testing;
