#!perl

package MyClass::Foo;

use Class::Root 'isa';

my $foo = __PACKAGE__;

package MyClass::Foo::LOCAL;

use strict;
use warnings;

class_initialize;

use declare m1 => virtual method;

class_verify;

package MyClass::Bar;

use MyClass::Foo "isa";

my $bar = __PACKAGE__; 

package MyClass::Bar::LOCAL;

use strict;
use warnings;

use Test::More tests => 1;
use English;

class_initialize;

eval "class_verify";
like($EVAL_ERROR,qr/Virtual method "m1" defined in class "MyClass::Foo" not implemented in derived class "MyClass::Bar"/,"DIED: virtual method not implemented")
