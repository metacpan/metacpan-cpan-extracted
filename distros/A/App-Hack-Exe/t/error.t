#!perl
use 5.012;
use warnings FATAL => 'all';

use Test::More 'no_plan';

require App::Hack::Exe;

my $he = App::Hack::Exe->new(no_delay => 1);

if (eval {
    $he->run;
    1;
}) {
    fail('->run() should abort if called without a hostname');
}
# Error message should mention it too.
like($@, qr/^No targets specified\./,
    '->run() should mention what went wrong'
);
