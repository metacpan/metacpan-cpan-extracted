use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Test::App::Wax qw(wax_is);
use Test::More tests => 4;

wax_is(
    'wax cmd foo bar baz',
    'cmd foo bar baz'
);

wax_is(
    'wax cmd -foo -bar -baz',
    'cmd -foo -bar -baz'
);

wax_is(
    'wax cmd --foo --bar --baz',
    'cmd --foo --bar --baz'
);

wax_is(
    'wax cmd foo -bar --baz',
    'cmd foo -bar --baz'
);
