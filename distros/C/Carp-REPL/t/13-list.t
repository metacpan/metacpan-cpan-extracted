#!perl
use strict;
use warnings;
use Test::More tests => 30;
use Test::Expect;

expect_run
(
    command => "$^X -Ilib -MCarp::REPL=noprofile t/scripts/12-env.pl",
    prompt  => '$ ',
    quit    => 'exit',
);

expect_send('1 + 1');
expect_like(qr/\b2\b/, 'in the REPL');

expect_send(':l');
expect_like(qr/12-env\.pl/, 'filename is given');
expect_like(qr/^\*49:     die \@_;/m, 'line with the error has a star');
expect_like(qr/^ 44:     \$closure->\(sort values \%args\);/m);
expect_like(qr/^ 45: \}/m);
expect_like(qr/^ 46: /m);
expect_like(qr/^ 47: sub five/m);
expect_like(qr/^ 48: \{/m);
expect_like(qr/^ 50: \}/m);
expect_like(qr/^ 51: /m);
expect_like(qr/^ 52: zero\(\);/m);
expect_like(qr/^ 53: /m);

expect_send(':u');
expect_like(qr/Now at.*frame 1/, 'up a frame');

expect_send(':l');
expect_like(qr/12-env\.pl/, 'filename is given');
expect_like(qr/^ 37: \{/m);
expect_like(qr/^ 38:     my \%args = \@_;/m);
expect_like(qr/^ 39: /m);
expect_like(qr/^ 40:     my \$closure = sub \{/m);
expect_like(qr/^ 41:         my \(\$alpha, \$beta, \$gamma, \$delta\) = \@_;/m);
expect_like(qr/^\*42:         five\(\$alpha \+ \$beta \+ \$gamma \+ \$delta\);/m);
expect_like(qr/^ 43:     \};/m);
expect_like(qr/^ 44:     \$closure->\(sort values %args\);/m);
expect_like(qr/^ 45: \}/m);
expect_like(qr/^ 46: /m);
expect_like(qr/^ 47: sub five/m);

