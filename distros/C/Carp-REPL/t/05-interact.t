#!perl
use strict;
use warnings;
use Test::More tests => 17;
use Test::Expect;

expect_run
(
    command => "$^X -Ilib -MCarp::REPL=noprofile t/scripts/05-interact.pl",
    prompt  => '$ ',
    quit    => 'exit',
);

expect_send('1 + 1');
expect_like(qr/\b2\b/, 'in the REPL');

expect_send('$surname_of{Christopher}');
expect_like(qr/\bWalken\b/);

expect_send('$surname_of{Christopher} = "Lee"');
expect_like(qr/\bLee\b/);

expect_send('$surname_of{Christopher}');
expect_like(qr/\bLee\b/);

expect_send('$pi = 31415');
expect_like(qr/\b31415\b/);

expect_send('call_me_when_you_have_pie()');
expect_like(qr/\b62830\b/);

expect_send('$main::pi = 314159');
expect_like(qr/\b314159\b/);

expect_send('call_me_when_you_have_pie()');
expect_like(qr/\b628318\b/);

