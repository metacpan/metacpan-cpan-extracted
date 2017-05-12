#!perl

use strict;
use warnings;

use Test::More 0.88 tests => 2;
use Capture::Tiny ':all';

my ($stdout, $stderr, $exit) = capture {
    system("'$^X' -Iblib/lib t/test-script.pl");
};

ok(defined($exit) && $exit == 0, 'Expect exit status of 0');

my $expected = <<'END_EXPECTED';
first call to atexit() returned value of type CODE
second call to atexit() returned value of type CODE
*** Leaving Scope 2 ***
cleanup() executing: args = Scope 2, Callback 2
*** Finished Scope 2 ***
*** Leaving Scope 1 ***
cleanup() executing: args = Scope 1, Callback 2
cleanup() executing: args = Scope 1, Callback 1
*** Finished Scope 1 ***
*** Now performing program-exit processing ***
cleanup() executing: args = This call was registered second
cleanup() executing: args = This call was registered first
END_EXPECTED

is($stdout, $expected, "Did we get expected output?");
