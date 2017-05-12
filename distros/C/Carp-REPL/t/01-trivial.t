#!perl
use strict;
use warnings;
use Test::More tests => 5;
use Test::Expect;

# basic sanity check: did we get a REPL on die?

expect_run
(
    command => "$^X -Ilib -MCarp::REPL=noprofile t/scripts/01-trivial.pl",
    prompt  => '$ ',
    quit    => 'exit',
);

expect_send('1 + 1');
expect_like(qr/2/);

# make sure the repl we have is Perl :)
expect_send('~~(3, 1, 4, 1)');
expect_like(qr/4/);

