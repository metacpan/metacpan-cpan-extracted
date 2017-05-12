use strict;
use warnings;
use Test::More tests => 2;
use B::Hooks::EndOfScope;
use B::Hooks::Parser;

BEGIN {
    B::Hooks::Parser::setup();
}

sub class (&) { }

# This would usually be a compilation error as class only expects one argument,
# but with the 'pass', there are two. After injecting a semicolon after the end
# of the block it becomes valid.
#
# We also insert lots of semicolons to make the resulting line larger than
# PL_linestr would usually be at this point. This is done to test the
# PL_linestr growing.

    class {
        BEGIN { on_scope_end {
            B::Hooks::Parser::inject(';' x 1024);
        } }
    }

pass;

# This checks that we can inject NULs.
no warnings "void";
BEGIN { B::Hooks::Parser::inject("is 'a', q\0a\0;"); }
'b';

1;
