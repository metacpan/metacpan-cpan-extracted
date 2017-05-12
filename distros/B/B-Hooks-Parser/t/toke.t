use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
    use_ok('B::Hooks::Parser');
    ok(B::Hooks::Toke->can("skipspace"));
    ok(B::Hooks::Toke->can("scan_word"));
}

