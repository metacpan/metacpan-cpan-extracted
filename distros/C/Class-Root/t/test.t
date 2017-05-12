#!perl

use constant CT_CHECKS => 1;
use constant RT_CHECKS => 1;

package MyClass::Foo;

my $class = __PACKAGE__;

use Class::Root 'isa';

package MyClass::Foo::LOCAL;

use strict;
use warnings;

use Test::More tests => 3;
use English;

declare private ca1 => class_attribute;

#1
can_ok($class, 'MyClass__Foo__ca1');

$class->_ca1 = 10;

#2
is($class->MyClass__Foo__ca1, 10, 'test 2');

declare class_attribute ca2 => 11;

declare overwrite class_init => class_method {
    my $class = shift;
    
    my %args = (
	ca2 => 12,	
    );

    $class->base_class_init( %args );
};

declare;
declare attributes qw( x1 y1 z1 );
declare x2 => setopts { value => 1},
	x3 => 5;

class_initialize;

class_verify;

package main;
use MyClass::Foo;
use Test::More;

#3
is($class->ca2, 12, 'test 3');

__DATA__
declare class_attribute a2 => 10;

#2
is($class->a2, 10, 'declare class_attribute NAME => VALUE;');

declare class_attribute a3 => setopts { value => 5 };

#3
is($class->a3, 5, 'declare class_attribute NAME seropts { value => VALUE };');

declare class_attribute a4;
declare setopts a4 => { value => 15 };

#4
is($class->a4, 15, 'declare class_attribute NAME; declare setopts NAME => { value => VALUE };');

declare a5 => class_attribute setopts { value => 25 };

#5
is($class->a5, 25, 'declare NAME => class_attribute setopts { value => VALUE };');

declare class_attribute a6 => aa;

#6
is($class->a6, "aa", 'declare class_attribute NAME => VALUE;');

declare class_attribute a7; &a7 = 47;

#7
is(&a7, 47, 'declare class_attribute NAME; &NAME = VALUE;');

eval "use declare class_attribute a8; a8 = 48;";

#8
is(&a8, 48, 'use declare class_attribute NAME; NAME = VALUE;');
#isnt($EVAL_ERROR, "", 'FAILED: declare class_attribute NAME; NAME = VALUE;');



