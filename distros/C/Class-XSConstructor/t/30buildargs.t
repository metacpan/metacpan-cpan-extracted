my $n;

{
	package Local::Foo;
	use Class::XSConstructor qw( foo bar );
	sub BUILDARGS {
		my ( $class, $foo, $bar ) = @_;
		++$n;
		return { foo => $foo, bar => $bar };
	}
}

use Test::More;

my $o = Local::Foo->new( 666, 42 );
is $n, 1;
is $o->{foo}, 666;
is $o->{bar}, 42;

done_testing;
