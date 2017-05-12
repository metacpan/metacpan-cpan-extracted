use strict;
use warnings;
use Test::More;

my $class;
BEGIN {
    use_ok($class='t::OverrideDefaultProperties', qw(Left Center Right));
}

# ----
# Helpers.

# ----
# Tests.
subtest 'default properties' => sub {
    is(Left  ->ordinal, -1, 'Left  ->ordinal');
    is(Center->ordinal,  0, 'Center->ordinal');
    is(Right ->ordinal,  1, 'Right ->ordinal');
    is(Left  ->name, 'L', 'Left  ->name');
    is(Center->name, 'C', 'Center->name');
    is(Right ->name, 'R', 'Right ->name');
};

# ----
done_testing;
