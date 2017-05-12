#!perl

package MyClass::Foo;

use Class::Root 'isa';

my $foo = __PACKAGE__;

package MyClass::Foo::LOCAL;

use strict;
use warnings;

use declare a1 => attribute;

class_initialize;
class_verify;

package MyClass::Bar;

use MyClass::Foo "isa";

my $bar = __PACKAGE__; 

package MyClass::Bar::LOCAL;

use strict;
use warnings;

use Test::More tests => 3;
use English;

#1
eval "use declare a1 => attribute";
like($EVAL_ERROR,qr/method "a1" already defined in base class "MyClass::Foo"/,"DIED: declaring already defined attribute");

#2
eval "use declare a1 => overwrite attribute";
like($EVAL_ERROR,qr/attributes couldn't be overwritten/,"DIED: declaring already defined attribute");

#3
eval "use declare a1 => class_attribute";
like($EVAL_ERROR,qr/method "a1" already defined in base class "MyClass::Foo"/,"DIED: declaring already defined attribute");


class_initialize;
class_verify;

package main;

use strict;
use warnings;

use Test::More;
use English;

