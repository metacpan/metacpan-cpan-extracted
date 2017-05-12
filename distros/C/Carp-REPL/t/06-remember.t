#!perl
use strict;
use warnings;
use Test::More tests => 11;
use Test::Expect;

# convenient test file for making sure we can still define vars and frob them

expect_run
(
    command => "$^X -Ilib -MCarp::REPL=noprofile t/scripts/01-trivial.pl",
    prompt  => '$ ',
    quit    => 'exit',
);

expect_send('1 + 1');
expect_like(qr/\b2\b/);

expect_send('my $string = q{hi}');
expect_like(qr/\bhi\b/);

expect_send('$string .= q{ya}');
expect_like(qr/\bhiya\b/);

expect_send('$string .= q{ck}');
expect_like(qr/\bhiyack\b/);

expect_send('$string =~ y/ia/eu/; $string');
expect_like(qr/\bheyuck\b/);

