package Jopa;
use Test::More ($] < 5.016) ? (skip_all => 'utf8 support on this perl is broken') : (no_plan);
use parent 'Class::Accessor::Inherited::XS::Compat';
use utf8;

my $utf8_acc = "тест";
my $nonutf_acc = "тест";
utf8::encode($nonutf_acc);

__PACKAGE__->mk_varclass_accessors($utf8_acc, $nonutf_acc);

Jopa->тест(42);
is(Jopa->тест , 42);
is(Jopa->$utf8_acc, 42);
is(${"Jopa::$utf8_acc"}, 42);
is(${"Jopa::$nonutf_acc"}, undef);

is(Jopa->$nonutf_acc(17), 17);
is(${"Jopa::$nonutf_acc"}, 17);

is(Jopa->$utf8_acc, 42);
is(${"Jopa::$utf8_acc"}, 42);
