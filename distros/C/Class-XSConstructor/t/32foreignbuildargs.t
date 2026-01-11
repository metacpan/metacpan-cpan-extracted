{
	package Local::Foo;
	sub new {
		my ( $class, $foo, $bar ) = @_;
		bless { foo => $foo, bar => $bar }, __PACKAGE__;
	}
}

{
	package Local::FooBar;
	use parent -norequire, 'Local::Foo';
	use Class::XSConstructor 'baz';
	sub FOREIGNBUILDARGS {
		my ( $self, $foo, $bar, $baz ) = @_;
		return ( $foo + 1, $bar + 1 );
	}
	sub BUILDARGS {
		my ( $self, $foo, $bar, $baz ) = @_;
		return { baz => $baz + 1 };
	}
}

use Test::More;

my $o = Local::FooBar->new( 666, 42, 99 );
is ref($o), 'Local::FooBar';
is $o->{foo}, 667;
is $o->{bar}, 43;
is $o->{baz}, 100;

done_testing;
