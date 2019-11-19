use strict;
use warnings;
use Test::More;
use Test::Requires { 'Type::Tiny' => '1.004000' };
use Test::Fatal;

{
	package Local::Foo;
	use Types::Standard 'Int', 'Num';
	use Class::Tiny::Antlers;
	has foo => (is => 'rw', isa => Int->plus_coercions(Num, sub { int($_) }), coerce => 1);
};

my $o1 = Local::Foo->new(foo => 42);
is($o1->foo, 42);
$o1->foo(43);
is($o1->foo, 43);
$o1->foo('44.1');
is($o1->foo, 44);

my $e = exception { $o1->foo('bar') };
like($e, qr/type constraint/i);

my $e2 = exception { Local::Foo->new(foo => 'baz') };
like($e2, qr/type constraint/i);

done_testing;
