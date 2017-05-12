#!perl

package MyClass::Foo;

my $class = __PACKAGE__;

use Class::Root 'isa';

package MyClass::Foo::LOCAL;

use Test::More tests => 6;
use English;

declare class_attribute a1;

declare class_attribute a2 => 10;

declare class_attribute a3 => setopts { value => 5 };

declare class_attribute a4;
declare setopts a4 => { value => 15 };

declare a5 => class_attribute setopts { value => 25 };

declare class_attribute a6 => "aa";


class_initialize;

#1
can_ok($class, 'a1');

#2
is($class->a2, 10, 'declare class_attribute NAME => VALUE;');

#3
is($class->a3, 5, 'declare class_attribute NAME seropts { value => VALUE };');

#4
is($class->a4, 15, 'declare class_attribute NAME; declare setopts NAME => { value => VALUE };');

#5
is($class->a5, 25, 'declare NAME => class_attribute setopts { value => VALUE };');

#6
is($class->a6, "aa", 'declare class_attribute NAME => VALUE;');

#declare class_attribute a7; &a7 = 47;
#
#7
#is(&a7, 47, 'declare class_attribute NAME; &NAME = VALUE;');
#
#eval "use declare class_attribute a8; a8 = 48;";
#
#8
#is(&a8, 48, 'use declare class_attribute NAME; NAME = VALUE;');
#isnt($EVAL_ERROR, "", 'FAILED: declare class_attribute NAME; NAME = VALUE;');

class_verify;
