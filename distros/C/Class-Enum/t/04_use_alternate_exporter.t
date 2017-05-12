use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok(
        't::UsingExporterTiny',
        (
            Left   => { -as => 'L' },
            Right  => { -as => 'R' },
        ),
    );
}

# ----
# Helpers.

# ----
# Tests.
subtest 'properties' => sub {
    is(L->name, 'Left' , 'L->name');
    is(R->name, 'Right', 'R->name');

    is(L->is_left ,  1, 'L->is_left');
    is(L->is_right, '', 'L->is_right');
    is(R->is_left , '', 'R->is_left');
    is(R->is_right,  1, 'R->is_right');
};

# ----
done_testing;
