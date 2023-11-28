#!perl
use 5.012;
use warnings FATAL => 'all';

use Test::More 'no_plan';

require App::Hack::Exe;

if (eval {
    App::Hack::Exe->new(
        no_delay => 1,
        unknown_parameter => 1,
    );
}) {
    fail('->new() should abort if given an unknown parameter');
}

# Error message should mention it too.
like($@, qr/unknown_parameter/,
    '->new() should mention what went wrong'
);
unlike($@, qr/no_delay/,
    '->new() should not mention what went right'
);
