use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Test::App::Wax qw(@KEEP @URL wax_is);
use Test::More tests => 4;

wax_is(
    "wax -c cmd --foo $URL[0]",
    "cmd --foo $KEEP[0]"
);

wax_is(
    "wax --cache cmd --foo $URL[0]",
    "cmd --foo $KEEP[0]"
);

wax_is(
    "wax -c cmd --foo $URL[0] -bar --baz $URL[1]",
    "cmd --foo $KEEP[0] -bar --baz $KEEP[1]"
);

wax_is(
    "wax --cache cmd --foo $URL[0] -bar --baz $URL[1]",
    "cmd --foo $KEEP[0] -bar --baz $KEEP[1]"
);
