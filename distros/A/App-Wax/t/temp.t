use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Test::App::Wax qw(@TEMP @URL wax_is);
use Test::More tests => 2;

wax_is(
    "wax cmd --foo $URL[0]",
    "cmd --foo $TEMP[0]"
);

wax_is(
    "wax cmd --foo $URL[0] -bar --baz $URL[1]",
    "cmd --foo $TEMP[0] -bar --baz $TEMP[1]"
);
