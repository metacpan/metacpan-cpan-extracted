#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 30;

BEGIN { 
    use_ok('Class::Throwable');
}

my $path_seperator = "/";
# MSWin32 perl works fine with "/"
$path_seperator = ":"  if $^O eq 'MacOS';

can_ok("Class::Throwable", 'throw');

# test without a message

eval { throw Class::Throwable };
isa_ok($@, 'Class::Throwable');

can_ok($@, 'getMessage');
is($@->getMessage(), 
  'An Class::Throwable Exception has been thrown', 
  '... the error is as we expected');

can_ok($@, 'toString');
is($@->toString(), 
  'Class::Throwable : An Class::Throwable Exception has been thrown', 
  '... the error is as we expected');

# test with a message 

eval { Class::Throwable->throw("Test Message") };
isa_ok($@, 'Class::Throwable');

is($@->getMessage(), 
  'Test Message',
  '... the error is as we expected');

is($@->toString(), 
  'Class::Throwable : Test Message', 
  '... the error is as we expected');
  
# test the stack trace now

can_ok($@, 'getStackTrace');
is_deeply(scalar $@->getStackTrace(),
        # these are the values in the stack trace:
        # $package, $filename, $line, $subroutine, 
        # $hasargs, $wantarray, $evaltext, $is_require
        [[ 'main', "t${path_seperator}10_Class_Throwable_test.t", '35', '(eval)', 0, undef, undef, undef ]],
        '... got the stack trace we expected');
        
is_deeply($@->getStackTrace(),
        # same thing in array context :)
        [ 'main', "t${path_seperator}10_Class_Throwable_test.t", '35', '(eval)', 0, undef, undef, undef ],
        '... got the stack trace we expected');   
        
can_ok($@, 'stackTraceToString');
is($@->stackTraceToString(),
   qq{  |--[ main::(eval) called in t${path_seperator}10_Class_Throwable_test.t line 35 ]},
   '... got the stack trace string we expected');    
   
ok(overload::Overloaded($@), '... stringified overload');

Class::Throwable->import(VERBOSE => 0);

is("$@", '', '... got the stringified result we expected');  

Class::Throwable->import(VERBOSE => 1);

is("$@", 'Class::Throwable : Test Message', '... got the stringified result we expected');  

Class::Throwable->import(VERBOSE => 2);

is("$@",
   qq{Class::Throwable : Test Message
  |--[ main::(eval) called in t${path_seperator}10_Class_Throwable_test.t line 35 ]
},
   '... got the stringified result we expected');    
   
my $e = $@;
eval { throw $e };
isa_ok($@, 'Class::Throwable');

is($@->stringValue(), $e->stringValue(), '... it is the same object, just re-thrown');

# some misc. weird stuff

eval {
    throw Class::Throwable [ 1 .. 5 ];
};
isa_ok($@, 'Class::Throwable');

is_deeply($@->getMessage(),
          [ 1 .. 5 ],
          '... you can use anything for a message');
                                                    
my $exception = Class::Throwable->new("A message for you");
isa_ok($exception, 'Class::Throwable');

is($exception->getMessage(), 'A message for you', '... got the message we expected');
is_deeply(scalar $exception->getStackTrace(), [], '... we dont have a stack trace yet');

eval {
	throw $exception;
};
isa_ok($@, 'Class::Throwable');
is($@, $exception, '... it is the same exception too');

is_deeply($@->getStackTrace(),
		  [ 'main', "t${path_seperator}10_Class_Throwable_test.t", '107', '(eval)', 0, undef, undef, undef ],
          '... got the stack trace we expected');  

{
    package Foo;
    sub foo { eval { Bar::bar() }; throw Class::Throwable "Foo!!", $@ }
    package Bar;
    sub bar { eval { Baz::baz() }; throw Class::Throwable "Bar!!", $@ }
    package Baz;
    sub baz { throw Class::Throwable "Baz!!" }
}

eval { Foo::foo() };

my $expected_big = <<EXPECTED_BIG;
Class::Throwable : Foo!!
  |--[ Foo::foo called in t${path_seperator}10_Class_Throwable_test.t line 126 ]
  |--[ main::(eval) called in t${path_seperator}10_Class_Throwable_test.t line 126 ]
  + Class::Throwable : Bar!!
      |--[ Bar::bar called in t${path_seperator}10_Class_Throwable_test.t line 119 ]
      |--[ Foo::(eval) called in t${path_seperator}10_Class_Throwable_test.t line 119 ]
      |--[ Foo::foo called in t${path_seperator}10_Class_Throwable_test.t line 126 ]
      |--[ main::(eval) called in t${path_seperator}10_Class_Throwable_test.t line 126 ]
      + Class::Throwable : Baz!!
          |--[ Baz::baz called in t${path_seperator}10_Class_Throwable_test.t line 121 ]
          |--[ Bar::(eval) called in t${path_seperator}10_Class_Throwable_test.t line 121 ]
          |--[ Bar::bar called in t${path_seperator}10_Class_Throwable_test.t line 119 ]
          |--[ Foo::(eval) called in t${path_seperator}10_Class_Throwable_test.t line 119 ]
          |--[ Foo::foo called in t${path_seperator}10_Class_Throwable_test.t line 126 ]
          |--[ main::(eval) called in t${path_seperator}10_Class_Throwable_test.t line 126 ]
EXPECTED_BIG

is($@->toString(2), $expected_big, '... got the big stack trace we were expecting');

  