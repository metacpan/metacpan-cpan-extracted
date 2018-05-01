use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Test::App::Wax qw(@TEMP @URL wax_is);
use Test::More tests => 15;

# implicit default separator (no option): --
wax_is(
    "wax cmd foo -bar --baz -- $URL[0] --quux",
    "cmd foo -bar --baz $URL[0] --quux"
);

# explicit default separator (short option): --
wax_is(
    "wax -s -- cmd foo -bar --baz -- $URL[0] --quux",
    "cmd foo -bar --baz $URL[0] --quux"
);

# explicit default separator (long option): --
wax_is(
    "wax --separator -- cmd foo -bar --baz -- $URL[0] --quux",
    "cmd foo -bar --baz $URL[0] --quux"
);

# no separator (short option)
wax_is(
    "wax -S cmd foo -bar -- $URL[0] --baz --quux",
    "cmd foo -bar -- $TEMP[0] --baz --quux"
);

# no separator (long option)
wax_is(
    "wax --no-separator cmd foo -bar -- $URL[0] --baz --quux",
    "cmd foo -bar -- $TEMP[0] --baz --quux"
);

# custom separator (short option): short separator
wax_is(
    "wax -s -X cmd foo -bar --baz -X $URL[0] --quux",
    "cmd foo -bar --baz $URL[0] --quux"
);

# custom separator (long option): short separator
wax_is(
    "wax --separator -X cmd foo -bar --baz -X $URL[0] --quux",
    "cmd foo -bar --baz $URL[0] --quux"
);

# custom separator (short option): long separator
wax_is(
    "wax -s --no-wax cmd foo -bar --baz --no-wax $URL[0] --quux",
    "cmd foo -bar --baz $URL[0] --quux"
);

# custom separator (long option): long separator
wax_is(
    "wax --separator --no-wax cmd foo -bar --baz --no-wax $URL[0] --quux",
    "cmd foo -bar --baz $URL[0] --quux"
);

# custom separator (short option): lowercase word
wax_is(
    "wax -s separator cmd foo -bar -- $URL[0] --baz separator $URL[0] --quux",
    "cmd foo -bar -- $TEMP[0] --baz $URL[0] --quux"
);

# custom separator (long option): lowercase word
wax_is(
    "wax --separator separator cmd foo -bar -- $URL[0] --baz separator $URL[0] --quux",
    "cmd foo -bar -- $TEMP[0] --baz $URL[0] --quux"
);

# custom separator (short option): uppercase word
wax_is(
    "wax -s SEPARATOR cmd foo -bar --baz SEPARATOR $URL[0] --quux",
    "cmd foo -bar --baz $URL[0] --quux"
);

# custom separator (long option): uppercase word
wax_is(
    "wax --separator SEPARATOR cmd foo -bar --baz SEPARATOR $URL[0] --quux",
    "cmd foo -bar --baz $URL[0] --quux"
);

# custom separator (short option): non-word
wax_is(
    "wax -s :: cmd foo -bar --baz :: $URL[0] --quux",
    "cmd foo -bar --baz $URL[0] --quux"
);

# custom separator (long option): non-word
wax_is(
    "wax --separator :: cmd foo -bar --baz :: $URL[0] --quux",
    "cmd foo -bar --baz $URL[0] --quux"
);
