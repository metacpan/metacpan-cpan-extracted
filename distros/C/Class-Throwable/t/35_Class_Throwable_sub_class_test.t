#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use lib qw(t/);

BEGIN {
    use_ok('TestException' => (VERBOSE => 2));
}

my $path_seperator = "/";
# MSWin32 perl works fine with "/"
$path_seperator = ":"  if $^O eq 'MacOS';

eval {
	throw TestException "This is my message";
};

my $expected = <<EXPECTED;
TestException : This is my message
  |--[ main::(eval) called in t${path_seperator}35_Class_Throwable_sub_class_test.t line 18 ]
EXPECTED

is($@, $expected, '... got the output we expected');

can_ok("TestException", 'setVerbosity');

TestException->setVerbosity(1);

eval {
	throw TestException "This is my other message";
};
is($@, 'TestException : This is my other message', '... got the output we expected');