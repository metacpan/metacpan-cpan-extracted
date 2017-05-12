#!perl
use strict;
use warnings;
use Test::More tests => 25;
use Test::Expect;

# make sure we can affect our environment

expect_run
(
    command => "$^X -Ilib t/scripts/08-alias.pl",
    prompt  => '$ ',
    quit    => 'exit',
);

expect_send('1 + 1');
expect_like(qr/2/);

expect_send('$denominator');
expect_like(qr/\b0\b/);

expect_send('$denominator = 5');
expect_like(qr/\b5\b/);

expect_send('$denominator');
expect_like(qr/\b5\b/);

expect_send('$denominator = 2');
expect_like(qr/\b2\b/);

expect_send('$denominator');
expect_like(qr/\b2\b/);

expect_send('$d = 4');
expect_like(qr/\b4\b/);

expect_send('$frac{d} ||= 250');
expect_like(qr/\b250\b/);

expect_send('$frac{d} ||= 250');
expect_like(qr/\b250\b/);

expect_send('%frac2 = (n => .1, d => .01)');

expect_send(':q');
expect_like(qr/<5>/);
expect_like(qr/<25>/);
expect_like(qr/<4>/);
expect_like(qr/<10>/);

