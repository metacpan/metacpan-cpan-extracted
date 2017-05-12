use strict;
use warnings;
use Test::More;

my $class;
BEGIN {
    use_ok($class='t::AdvancedUsage', qw(Left Right));
}

# ----
# Helpers.

# ----
# Tests.
subtest 'properties' => sub {
    is(Left ->delta, -1, 'Left ->delta');
    is(Right->delta,  1, 'Right->delta');
};

subtest 'methods' => sub {
    is(Left ->move(5), 4, 'Left ->move(5)');
    is(Right->move(5), 6, 'Right->move(5)');
};

# ----
done_testing;
