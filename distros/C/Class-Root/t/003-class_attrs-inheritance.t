#!perl

package MyClass::Foo;

use Class::Root 'isa';

my $foo = __PACKAGE__;

package MyClass::Foo::LOCAL;

use declare class_attribute ca1 => 10;
use declare class_attribute ca10 => setopts {
    check_value => sub {
	( 10 < $_ and $_ < 25 ) ? "" : return "10 < X < 25";
    },
};

use declare class_attribute ca11 => 5;

class_initialize;

class_verify;

package MyClass::Bar;

use MyClass::Foo "isa";

my $bar = __PACKAGE__; 

package MyClass::Bar::LOCAL;

use Test::More tests => 10;
use English;

use declare class_attribute ca2 => 12;

declare setopts ca10 => {
    check_value => sub {
	( 20 < $_ and $_ < 25 ) ? "" : return "20 < X < 25";
    },
};

declare setopts ca11 => {
    value => 11,
    check_value => sub {
	( $_ > 10 ) ? "" : return "X > 10";
    },
};

declare override class_init => class_method {
    my $class = shift;
    $class->base_class_init( ca11 => 12, @_ );
};

class_initialize;

#1
is($bar->isa($foo), 1, "$bar->isa(\'$foo\')");

#2
can_ok($bar, "ca1");

#3
can_ok($bar, "ca2");

eval "$bar->ca1 = 5";

#4
is($EVAL_ERROR, "", 'ca1 = 5');

eval "$bar->ca2 = 6";

#5
is($EVAL_ERROR, "", 'ca2 = 6');

eval {$foo->ca10 = 15};

#6
is( $EVAL_ERROR, "", "$foo->ca10 = 15");

eval {$bar->ca10 = 15};

#7
like( $EVAL_ERROR, qr/check_value error/, "DIED: $bar->ca10 = 15");

#8
is($bar->ca11, 12, "ca11 eq 12");

eval "$bar->ca11 = 7";

#9
like( $EVAL_ERROR, qr/check_value error/, "DIED: $bar->ca11 = 7");

eval "$foo->ca11 = 7";
#10
is( $EVAL_ERROR, "", "$foo->ca11 = 7");

class_verify;
