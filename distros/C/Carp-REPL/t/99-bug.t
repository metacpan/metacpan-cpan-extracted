#!perl
use strict;
use warnings;
use Test::More tests => 3;
use Test::Expect;

expect_run
(
    command => "$^X -Ilib -MCarp::REPL=noprofile t/scripts/07-frame.pl",
    prompt  => '$ ',
    quit    => 'exit',
);

expect_send(':u');
expect_like(qr{\bNow at t/scripts/07-frame\.pl:9 \(frame 1\)\.}, ":up as first command doesn't work");


