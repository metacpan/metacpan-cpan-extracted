#!perl
use strict;
use warnings;
use Test::More tests => 26;
use Test::Expect;

expect_run
(
    command => "$^X -Ilib -MCarp::REPL=noprofile t/scripts/09-args.pl",
    prompt  => '$ ',
    quit    => 'exit',
);

expect_send('1 + 1');
expect_like(qr/\b2\b/, 'in the REPL');

expect_send('@$_a');
expect_like(qr/\b10\b/);

expect_send(':u');
expect_send('@$_a');
expect_like(qr/\b10\b/);

expect_send(':u');
expect_send('sort @$_a');
expect_like(qr/\b1 2 3 4\b/);

expect_send(':u');
expect_send('sort @$_a');
expect_like(qr/\b1 2 3 4 Be H He Li\b/);

expect_send(':u');
expect_send('@$_a');
expect_like(qr/\bI is I\b/);

expect_send(':u');
expect_send('@$_a');
expect_like(qr/\bI I\b/);

expect_send(':u');
expect_send('"<@$_a>"');
expect_like(qr/^<I>$/m);

expect_send(':u');
expect_send('"<@$_a>"');
expect_like(qr/^<>$/m);

