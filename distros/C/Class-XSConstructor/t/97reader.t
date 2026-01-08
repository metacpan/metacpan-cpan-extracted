use strict;
use warnings;
use Test::More;
use Test::Requires { 'Types::Standard' => '1.000000' };

BEGIN {
	package Local::Foo;
	use Class::XSConstructor 'foo';
	use Types::Standard;
	Class::XSConstructor::install_reader(
		__PACKAGE__ . '::get_foo',
		'foo',
		1,
		0,
		sub { 42 },
		15,
		\&Types::Standard::is_Int,
		undef,
	);
};

my $x = Local::Foo->new;
is_deeply( $x, bless({}, 'Local::Foo') );
is( $x->get_foo, 42 );
is_deeply( $x, bless({foo=>42}, 'Local::Foo') );

BEGIN {
	package Local::Foo2;
	use Class::XSConstructor 'foo';
	use Types::Standard;
	Class::XSConstructor::install_reader(
		__PACKAGE__ . '::get_foo',
		'foo',
		1,
		0,
		sub { "Bad" },
		15,
		\&Types::Standard::is_Int,
		undef,
	);
};

my $y = Local::Foo2->new;
is_deeply( $y, bless({}, 'Local::Foo2') );
ok !eval { $y->get_foo; 1 };
is_deeply( $y, bless({}, 'Local::Foo2') );

done_testing;