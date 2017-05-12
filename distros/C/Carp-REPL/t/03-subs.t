#!perl
use strict;
use warnings;
use Test::More tests => 31;
use Test::Expect;

expect_run
(
    command => "$^X -Ilib -MCarp::REPL=noprofile t/scripts/03-subs.pl",
    prompt  => '$ ',
    quit    => 'exit',
);

expect_send('1 + 1');
expect_like(qr/2/, 'in the REPL');

expect_send('latency()');
expect_like(qr/\bhigh\b/, 'thunk');

expect_send('fib(4)');
expect_like(qr/\b24\b/, 'procedure of one argument');

expect_send('unicounter()');
expect_like(qr/\b1\b/, 'closure (simple counter) 1/4');

expect_send('unicounter()');
expect_like(qr/\b2\b/, 'closure (simple counter) 2/4');

expect_send('unicounter()');
expect_like(qr/\b3\b/, 'closure (simple counter) 3/4');

expect_send('my $from10 = make_counter(10)');
expect_like(qr/\bCODE\b/, 'closure-producing procedure gives a CODEREF 1/2');

expect_send('my $from3 = make_counter(3)');
expect_like(qr/\bCODE\b/, 'closure-producing procedure gives a CODEREF 2/2');

expect_send('$from10->()');
expect_like(qr/\b11\b/, 'calling the from10 counter 1/2');

expect_send('$from3->()');
expect_like(qr/\b4\b/, 'calling the from3 counter 1/2');

expect_send('$from3->()');
expect_like(qr/\b5\b/, 'calling the from3 counter 2/2');

expect_send('$from10->()');
expect_like(qr/\b12\b/, 'calling the from10 counter 2/2');

expect_send('unicounter()');
expect_like(qr/\b4\b/, 'closure (simple counter) 4/4');

expect_send('other_package()');
expect_like(qr/\bUndefined subroutine\b/, 'sub from Other::Package isn\'t visible in main');

expect_send('Other::Package::other_package()');
expect_like(qr/\bhooray!/, 'sub from Other::Package is visible if we include the package name');

