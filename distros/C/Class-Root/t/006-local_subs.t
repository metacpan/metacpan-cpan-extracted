#!perl

BEGIN { $Carp::Verbose = 1 };

package MyClass::Foo;

use Class::Root 'isa';

my $foo = __PACKAGE__;

package MyClass::Foo::LOCAL;

use strict;
use warnings;

use Test::More tests => 36;
use English;

use declare '+DEFINE_LOCAL_SUBS';
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

use declare method_a33 => method sub ():lvalue {
    local $_ = shift || $_;
    _ro_a3;
};


#1
is($foo->_priv_ca2, 2, "Foo->__priv_ca2 eq 2");

#2
is(_priv_ca2, 2, "_priv_ca2 eq 2");

#3
$foo->_ro_ca3 = 33;
is($foo->ro_ca3, 33, "Foo->__ro_ca3 = 33");

#4
_ro_ca3 = 330;
is(ro_ca3, 330, "_ro_ca3 = 330");

#5
eval "$foo->ro_ca3 = 333";
like( $EVAL_ERROR, qr/Can't modify non-lvalue subroutine/, "DIED: Foo->ro_ca3 = 333 (setting ro attribute)");

#6
eval "ro_ca3 = 333";
like( $EVAL_ERROR, qr/Can't modify non-lvalue subroutine/, "DIED: ro_ca3 = 333 (setting ro attribute)");

#7
eval "$foo->ro_ca3(333)";
like( $EVAL_ERROR, qr/couldn't set read only class attribute "ro_ca3"/, "DIED: Foo->ro_ca3(333) (setting ro attribute)");

#8
$foo->_prot_ca4 = 44;
is($foo->_prot_ca4, 44, "Foo->__prot_ca4 = 44");

#9
_prot_ca4 = 440;
is($foo->_prot_ca4, 440, "_prot_ca4 = 440");

#10
$foo->_prot_ro_ca5 = 55;
is($foo->_prot_ro_ca5, 55, "Foo->__prot_ro_ca5 = 55");

#11
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

use declare '+DEFINE_LOCAL_SUBS';

#12
is($foo->ca1, 1, "Foo->ca1 eq 1");

#13
can_ok($bar, "ca1");

#14
is($bar->ca1, 1, "Bar->ca1 eq 1");

#15
$bar->ca1 = 5;
is($bar->ca1, 5, "Bar->ca1 = 5");

#16
is($foo->ca1, 1, "Foo->ca1 is still 1 ");

#17
$_ = $foo;
is(ca1, 5, "ca1 is 5 (default_class Bar)");

#18
eval {$foo->_priv_ca2};
like( $EVAL_ERROR, qr/Can't locate object method/, "DIED: Foo->__priv_ca2 (calling other's private method)");

#19
is($bar->ro_ca3, 3, 'Bar->ro_ca3 eq 3');

#20
eval "$bar->_ro_ca3 = 777";
like( $EVAL_ERROR, qr/Can't locate object method/, "DIED: Bar->__ro_ca3 (calling other's private method)");

#21
eval "_ro_ca3 = 777";
like( $EVAL_ERROR, qr/Can't modify constant item in scalar/, "DIED: _ro_ca3 = 777 (calling other's private method)");

#22
$bar->_prot_ca4 = 444;
is($bar->_prot_ca4, 444, 'Bar->_prot_ca4 = 444');

#23
eval "$bar->prot_ro_ca5 = 555";
like( $EVAL_ERROR, qr/Can't modify non-lvalue subroutine/, "DIED: Bar->prot_ro_ca5 = 555 (setting ro attribute)");

class_verify;

package main;

use strict;
use warnings;

use Test::More;
use English;

use MyClass::Foo qw(+DEFINE_LOCAL_SUBS);
use MyClass::Bar qw(+DEFINE_LOCAL_SUBS);

#24
eval {$bar->_prot_ca4 = 4444};
like( $EVAL_ERROR, qr/Can't locate object method/, "DIED: Bar->_prot_ca4 (calling other's private method)");

#25
is($bar->prot_ro_ca5, 5, 'Bar->prot_ro_ca5 eq 5');

#26
$_ = $bar;
is(prot_ro_ca5, 5, 'prot_ro_ca5 eq 5');

my $f = $foo->new;
my $b = $bar->new;

#27
is($f->a1, $b->a1, 'f->a1 eq b->a1');

#28
is($f->ca1, 1, 'f->ca1 eq 1');

#29
is($b->ca1, 5, 'b->ca1 eq 5');

#30
$b->a1 = 111;
is($b->a1, 111, 'b->a1 = 111');

#31
$_ = $b;
a1 = 1111;
is($b->a1, 1111, 'a1 = 1111');

#32
eval {$b->_ro_a3 = 133};
like( $EVAL_ERROR, qr/Can't locate object method/, "DIED: b->_ro_a3 (calling other's private method)");

#33
$b->method_a3 = 133;
is($b->ro_a3, 133, "b->method_a3 = 133");

#34
local $_ = $b;
method_a33 = 144;
is($b->ro_a3, 144, "method_a33 = 144");

#35
$_ = $b;
$f->method_a33 = 155;
is($b->ro_a3, 144, "f->method_a33 = 155 b->ro_a3 still 144");

#36
is($f->ro_a3, 155, "f->ro_a3 eq 155");

