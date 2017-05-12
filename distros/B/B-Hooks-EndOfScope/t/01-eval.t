use strict;
use warnings;
use Test::More 0.88;

use B::Hooks::EndOfScope;

# FIXME!!!!! this is dreadful. This test is written so loosely that we still
# pass all tests if we comment out the above use_ok line and replace it with:
# sub on_scope_end(&) { shift->() }

our $called;

sub foo {
    BEGIN { on_scope_end { $called = 1 } }

    # uncomment this to make the test pass
    eval '42';
}

BEGIN {
    ok($called, 'callback invoked');
}

done_testing;
