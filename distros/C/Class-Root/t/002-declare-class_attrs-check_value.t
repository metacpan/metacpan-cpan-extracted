#!perl

package MyClass::Foo;

use Class::Root 'isa';

my $foo = __PACKAGE__;

package MyClass::Foo::LOCAL;

use Test::More tests => 4;
use English;

declare class_attribute a1 => setopts {
    value => 11,
    check_value => sub {
	return "10 < X < 25" if ( $_ <= 10 or $_ >= 25 );
        return "";
    },
};

declare class_attribute a2 => setopts {
    check_value => sub {
	/XXX/ ? "" : "Schould contain XXX";
    },
};

class_initialize;

#1
is( $foo->a1, 11, 'declare class_attribute NAME => setopts { value => 11, check_value => sub { 10 < X < 25 }');

eval { $foo->a1 = 5 };

#2
like($EVAL_ERROR, qr/check_value error.*10 < X < 25/, 'DIED: &NAME = 5 (check_value => sub { 10 < X < 25 })' );

eval '$foo->a2 = "aaaa XXXXX bbbb"';

#3
is($EVAL_ERROR, "", 'NAME = "aaaa XXXXX bbbb" ( check_value => sub ( /XXX/ ? ... )' );

eval '$foo->a2 = "aaaa bbbb"';

#4
like($EVAL_ERROR, qr/check_value error.*Schould contain XXX/, 'DIED: NAME = "aaaa bbbb" ( check_value => sub ( /XXX/ ? ... )' );

class_verify;
