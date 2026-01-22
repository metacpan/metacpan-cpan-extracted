use Test::More;

BEGIN {
	package Local::Foo;
	use Class::XSConstructor
		foo => { is => 'ro' },
		bar => { clone => 1 };
};

my $hash = { xyz => 666 };
my $obj  = Local::Foo->new( foo => $hash, bar => $hash );

is( $obj->{foo}{xyz}, 666 );
is( $obj->{bar}{xyz}, 666 );

$hash->{xyz} = 999;

is( $obj->{foo}{xyz}, 999 );
is( $obj->{bar}{xyz}, 666 );

BEGIN {
	package Local::Bar;
	use Class::XSConstructor
		bar => {
			isa => sub {
				my $val = shift;
				!ref($val) and $val =~ /\A-?[0-9]+\z/;
			},
			clone => sub {
				my ( $self, $attr, $value ) = @_;
				::isa_ok( $self, __PACKAGE__ );
				::is( $attr, 'bar' );
				::is( $value, 42 );
				::is( scalar(@_), 3 );
				our $CALLED; $CALLED++;
				return "xx$value";
			},
		};
};

my $e = do {
	local $@;
	eval { Local::Bar->new( bar => 42 ) };
	$@;
};

is( $Local::Bar::CALLED, 1 );
like( $e, qr/^Cloning result 'xx42' failed type constraint for 'bar'/ );

done_testing;
