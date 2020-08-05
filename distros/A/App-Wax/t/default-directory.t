use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Test::App::Wax qw(@DEFAULT @URL wax_is);
use Test::More tests => 4;

wax_is(
    "wax --cache --default-directory cmd --foo $URL[0]",
    "cmd --foo $DEFAULT[0]"
);

wax_is(
    "wax --cache -D cmd --foo $URL[0]",
    "cmd --foo $DEFAULT[0]"
);

wax_is(
    "wax -c --default-directory cmd --foo $URL[0]",
    "cmd --foo $DEFAULT[0]"
);

wax_is(
    "wax -c -D cmd --foo $URL[0]",
    "cmd --foo $DEFAULT[0]"
);
