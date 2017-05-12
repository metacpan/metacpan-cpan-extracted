use Test::More tests => 1;

{
	package Local::Foo;
	sub create { bless [] => shift };
}

use Acme::Constructor::Pythonic
	main => {
		class       => 'Local::Foo',
		constructor => 'create',
		alias       => 'LocalFu',
		no_require  => 1,
	};
	
isa_ok( LocalFu(), 'Local::Foo' );
