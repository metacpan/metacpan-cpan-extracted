{
	package Local::Foo;
	use Class::XSConstructor foo => {
		slot_initializer => sub {
			my ( $self, $value ) = @_;
			die if defined wantarray;
			$self->{FOO} = $value;
		},
	};
}

use Test::More;

is_deeply( Local::Foo->new( foo => 42 ), bless( { FOO => 42 }, 'Local::Foo' ) );
done_testing;