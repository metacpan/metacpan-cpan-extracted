#!perl

package MyClass::Foo;

use Class::Root 'isa';

my $foo = __PACKAGE__;

package MyClass::Foo::LOCAL;

use strict;
use warnings;

use Test::More tests => 25;
use English;

use declare class_attribute ca1 => 1;
use declare private class_attribute _priv_ca2 => 2;
use declare readonly class_attribute ro_ca3 => 3;
use declare protected class_attribute _prot_ca4 => 4;
use declare protected readonly class_attribute _prot_ro_ca5 => 5;

class_initialize;

use declare attribute a1 => 101;
use declare private attribute _priv_a2 => 102;
use declare readonly attribute ro_a3 => 103;
use declare protected attribute _prot_a4 => 104;
use declare protected readonly attribute _prot_ro_a5 => 105;

declare method_a3 => method sub :lvalue {
    my $self = shift;
    $self->_ro_a3;
};

#1
is($foo->_priv_ca2, 2, "Foo->__priv_ca2 eq 2");

#2
$foo->_ro_ca3 = 33;
is($foo->ro_ca3, 33, "Foo->__ro_ca3 = 33");

#3
eval "$foo->ro_ca3 = 333";
like( $EVAL_ERROR, qr/Can't modify non-lvalue subroutine/, "DIED: Foo->ro_ca3 = 333 (setting ro attribute)");

#4
eval "$foo->ro_ca3(333)";
like( $EVAL_ERROR, qr/couldn't set read only class attribute "ro_ca3"/, "DIED: Foo->ro_ca3(333) (setting ro attribute)");

#5
$foo->_prot_ca4 = 44;
is($foo->_prot_ca4, 44, "Foo->__ro_ca4 = 44");

#6
$foo->_prot_ro_ca5 = 55;
is($foo->_prot_ro_ca5, 55, "Foo->__prot_ro_ca5 = 55");

#7
eval "$foo->prot_ro_ca5 = 555";
like( $EVAL_ERROR, qr/Can't modify non-lvalue subroutine/, "DIED: Foo->prot_ro_ca5 = 555 (setting ro attribute)");

class_verify;

package MyClass::Bar;

use MyClass::Foo "isa";

my $bar = __PACKAGE__; 

package MyClass::Bar::LOCAL;

use strict;
use warnings;

use Test::More;
use English;

class_initialize;

#8
is($foo->ca1, 1, "Foo->ca1 eq 1");

#9
can_ok($bar, "ca1");

#10
is($bar->ca1, 1, "Bar->ca1 eq 1");

#11
$bar->ca1 = 5;
is($bar->ca1, 5, "Bar->ca1 = 5");

#12
is($foo->ca1, 1, "Foo->ca1 is still 1 ");

#13
eval {$foo->_priv_ca2};
like( $EVAL_ERROR, qr/Can't locate object method/, "DIED: Foo->__priv_ca2 (calling other's private method)");

#14
is($bar->ro_ca3, 3, 'Bar->ro_ca3 eq 3');

eval "$bar->_ro_ca3 = 777";
#15
like( $EVAL_ERROR, qr/Can't locate object method/, "DIED: Bar->__ro_ca3 (calling other's private method)");

#16
$bar->_prot_ca4 = 444;
is($bar->_prot_ca4, 444, 'Bar->_prot_ca4 = 444');

#17
eval "$bar->prot_ro_ca5 = 555";
like( $EVAL_ERROR, qr/Can't modify non-lvalue subroutine/, "DIED: Bar->prot_ro_ca5 = 555 (setting ro attribute)");

class_verify;

package main;

use strict;
use warnings;

use Test::More;
use English;

#18
eval {$bar->_prot_ca4 = 4444};
like( $EVAL_ERROR, qr/Can't locate object method/, "DIED: Bar->_prot_ca4 (calling other's private method)");

#19
is($bar->prot_ro_ca5, 5, 'Bar->prot_ro_ca5 eq 5');

my $f = $foo->new;
my $b = $bar->new;

#20
is($f->a1, $b->a1, 'f->a1 eq b->a1');

#21
is($f->ca1, 1, 'f->ca1 eq 1');

#22
is($b->ca1, 5, 'b->ca1 eq 5');

#23
$b->a1 = 111;
is($b->a1, 111, 'b->a1 = 111');

#24
eval {$b->_ro_a3 = 133};
like( $EVAL_ERROR, qr/Can't locate object method/, "DIED: b->_ro_a3 (calling other's private method)");

#25
$b->method_a3 = 133;
is($b->ro_a3, 133, "b->method_a3 = 133");
