use strict;
use warnings;
use Test::More 0.88;

BEGIN { use_ok('B::Hooks::EndOfScope') }

# FIXME!!!!! this is dreadful. This test is written so loosely that we still
# pass all tests if we comment out the above use_ok line and replace it with:
# sub on_scope_end(&) { shift->() }


BEGIN {
    ok(exists &on_scope_end, 'on_scope_end imported');
    is(prototype('on_scope_end'), '&', '.. and has the right prototype');
}

our ($i, $called);

BEGIN { $i = 0 }

sub foo {
    BEGIN {
        on_scope_end { $called = 1; $i = 42 };
        on_scope_end { $i = 1 };
    };

    is($i, 1, 'value still set at runtime');
}

BEGIN {
    ok($called, 'first callback invoked');
    is($i, 1, '.. but the second is invoked later')
}

foo();

done_testing;
