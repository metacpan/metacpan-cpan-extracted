#!perl -w

use strict;
use Test::More tests => 8;
use Test::Exception;

BEGIN{
	use_ok 'Data::Util::Error';
}

{

	package Foo;
	use Data::Util::Error \&fail;
	use Data::Util qw(:validate);

	sub f{
		array_ref(@_);
	}

	sub fail{ 'FooError' }
}
{
	package Bar;
	use Data::Util::Error \&fail;
	use Data::Util qw(:validate);

	sub f{
		array_ref(@_);
	}

	sub fail{ 'BarError' }
}

{
	package Baz;
	use base qw(Foo Bar);
	use Data::Util qw(:validate);

	sub g{
		array_ref(@_);
	}
}

is( Data::Util::Error->fail_handler('Foo'), \&Foo::fail );
is( Data::Util::Error->fail_handler('Bar'), \&Bar::fail );
is( Data::Util::Error->fail_handler('Baz'), \&Foo::fail );


throws_ok{
	Foo::f({});
} qr/FooError/;
throws_ok{
	Bar::f({});
} qr/BarError/;

throws_ok{
	Baz::g({});
} qr/FooError/;


throws_ok{
	Data::Util::Error->fail_handler(Foo => 'throw');
} qr/Validation failed/;
