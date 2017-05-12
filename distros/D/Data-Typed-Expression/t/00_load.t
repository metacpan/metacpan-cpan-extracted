
use Test::More tests => 2;

BEGIN {
	for ( qw( Data::Typed::Expression Data::Typed::Expression::Env ) ) {
		use_ok( $_ ) or BAIL_OUT "Can't load $_";
	}
}

