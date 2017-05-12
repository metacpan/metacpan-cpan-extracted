#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 17;

BEGIN {
    use_ok('Class::Throwable');
}

my $path_seperator = "/";
# MSWin32 perl works fine with "/"
$path_seperator = ":"  if $^O eq 'MacOS';

eval {
	throw Class::Throwable "This is our first exception";
};
my $e1 = $@;
isa_ok($e1, 'Class::Throwable');

eval {
    throw Class::Throwable "This is our second exception", $e1;
};
my $e2 = $@;
isa_ok($e2, 'Class::Throwable');

eval {
    throw Class::Throwable "This is our third exception", $e2;
};
my $e3 = $@;
isa_ok($e3, 'Class::Throwable');

can_ok($e1, 'hasSubException');
can_ok($e1, 'getSubException');
can_ok($e1, 'stringValue');

ok(!$e1->hasSubException(), '... e1 does not have a sub-exception');

ok($e2->hasSubException(), '... e2 does have a sub-exception');
is($e2->getSubException()->stringValue(), $e1->stringValue(), '... e2\'s sub-exception is e1');

ok($e3->hasSubException(), '... e3 does have a sub-exception');
is($e3->getSubException()->stringValue(), $e2->stringValue(), '... e3\'s sub-exception is e2');

my $expected = <<EXPECTED;
Class::Throwable : This is our third exception
  |--[ main::(eval) called in t${path_seperator}20_Class_Throwable_subException_test.t line 28 ]
  + Class::Throwable : This is our second exception
      |--[ main::(eval) called in t${path_seperator}20_Class_Throwable_subException_test.t line 22 ]
      + Class::Throwable : This is our first exception
          |--[ main::(eval) called in t${path_seperator}20_Class_Throwable_subException_test.t line 16 ]
EXPECTED

is($e3->toString(2), $expected, '... toString prints subexceptions too');

eval {
    my $test = sub { $_[0] / 0 };
    eval { $test->(2) };
    throw Class::Throwable "Testing non-object sub-Exceptions", $@;
};
isa_ok($@, 'Class::Throwable');

ok($@->hasSubException(), '... we do have a sub-exception');
like($@->getSubException(), 
     qr/Illegal division by zero/, 
     '... our sub-exception is a string');
     
my $expected2 = <<EXPECTED2;
Class::Throwable : Testing non-object sub-Exceptions
  |--[ main::(eval) called in t${path_seperator}20_Class_Throwable_subException_test.t line 57 ]
  + Illegal division by zero at t${path_seperator}20_Class_Throwable_subException_test.t line 58.
EXPECTED2

is($@->toString(2), $expected2, '... toString prints what we expected');
