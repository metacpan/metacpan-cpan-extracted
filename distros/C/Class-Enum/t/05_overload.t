use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('t::OverloadStringify', qw(false true));
}

# ----
subtest 'override default overload settings' => sub {
    is(''.false, '0', 'false as string');
    is(''.true , '1', 'true as string');
};

# ----
done_testing;
