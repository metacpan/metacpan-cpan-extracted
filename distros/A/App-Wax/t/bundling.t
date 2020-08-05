use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Test::App::Wax qw(@DEFAULT @URL wax_is);
use Test::More tests => 2;

wax_is(
    "wax -cD cmd --foo $URL[0]",
    "cmd --foo $DEFAULT[0]"
);

wax_is(
    "wax -Dc cmd --foo $URL[0]",
    "cmd --foo $DEFAULT[0]"
);
