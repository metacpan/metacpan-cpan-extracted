use strict;
use warnings;
use Test::More;

BEGIN {
	package Local::Foo;
	use Class::XSConstructor;
	sub xyz {
		shift;
		if ( @_ ) {
			return join 'x', @_;
		}
		return 'x';
	}
};

BEGIN {
	package Local::Bar;
	use Class::XSConstructor 'foo';
	use Class::XSDelegation
		[ fooxyz  => foo => xyz => {} ],
		[ fooxyz2 => foo => xyz => { curry => [ 1, 2, 3 ] } ],
		[ fooxyz3 => foo => xyz => { is_try => 1 } ];
};

my $foo = Local::Foo->new;
my $bar = Local::Bar->new( foo => $foo );

is( $bar->fooxyz, 'x' );
is( $bar->fooxyz(1, 2), '1x2' );
is( $bar->fooxyz2, '1x2x3' );
is( $bar->fooxyz2(4..9), join('x', 1..9) );

$bar->{foo} = [];

{
	my $e = do {
		local $@;
		eval { $bar->fooxyz };
		$@;
	};
	like $e, qr/^Expected blessed object to delegate to; got ARRAY/;
}

is( $bar->fooxyz3, undef );

delete $bar->{foo};

{
	my $e = do {
		local $@;
		eval { $bar->fooxyz };
		$@;
	};
	like $e, qr/^Expected blessed object to delegate to; got undef/;
}

is( $bar->fooxyz3, undef );

done_testing;
