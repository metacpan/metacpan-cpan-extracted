use strict;
use warnings;
use Test::More;
use Test::Requires 'Specio::Library::Builtins';
use Test::Fatal;

{
	package Local::Foo;
	use Specio::Library::Builtins 'Int';
	use Class::Tiny::Antlers;
	has foo => (is => 'rw', isa => t('Int'));
};

my $o1 = Local::Foo->new(foo => 42);
is($o1->foo, 42);
$o1->foo(43);
is($o1->foo, 43);

my $e = exception { $o1->foo('bar') };
like($e, qr/type constraint/i);

my $e2 = exception { Local::Foo->new(foo => 'baz') };
like($e2, qr/type constraint/i);

done_testing;
