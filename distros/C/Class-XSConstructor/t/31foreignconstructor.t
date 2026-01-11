{
	package Local::Foo;
	sub new {
		my ( $class, $foo, $bar ) = @_;
		# Deliberately bless into wrong package
		bless { foo => $foo, bar => $bar }, __PACKAGE__;
	}
}

{
	package Local::FooBar;
	use parent -norequire, 'Local::Foo';
	use Class::XSConstructor baz => { init_arg => undef, default => 33 };
}

use Test::More;

my $o = Local::FooBar->new( 666, 42 );
is ref($o), 'Local::FooBar';
is $o->{foo}, 666;
is $o->{bar}, 42;
is $o->{baz}, 33;

done_testing;
