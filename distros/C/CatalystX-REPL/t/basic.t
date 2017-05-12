use strict;
use warnings;
use Test::More tests => 5;
use Test::Expect;

expect_run(
    command => "${^X} t/request.pl /foo/bar",
    prompt  => '$ ',
    quit    => 'exit'
);

expect_send('1 + 1');
expect_like(qr/\b2\b/, 'in the REPL');

expect_send(':t');
expect_like(qr/\bTestApp::Controller::Foo::bar\b/, 'exception in controller action');
