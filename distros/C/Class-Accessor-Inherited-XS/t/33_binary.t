package Jopa;
use parent 'Class::Accessor::Inherited::XS::Compat';
use Test::More (Class::Accessor::Inherited::XS::BINARY_UNSAFE) ? (skip_all => 'binary support on this perl is broken') : (no_plan);
use utf8;

my $binary_key = "foo\0bar";
__PACKAGE__->mk_inherited_accessors($binary_key, "foo");

is(Jopa->${\$binary_key}(42), 42);
is(Jopa->foo, undef);

is(Jopa->foo(17), 17);
is(Jopa->$binary_key, 42);

is(${"Jopa::__cag_$binary_key"}, 42);
is(${"Jopa::__cag_foo"}, 17);
