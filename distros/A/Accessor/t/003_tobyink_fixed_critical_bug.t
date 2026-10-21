# -*- perl -*-

# t/002_basic.t - basic Accessor tests

use Test::More tests => 2;

BEGIN { use_ok( 'Accessor' ); }

ok( (sub { 
	my $obj = new Hash;
	$obj->attr(1);
	return $obj->attr() == 1;
})->(), 'Getting attr' );


package Hash;

use base 'Accessor';

sub new {
	my $class = shift;
	return bless {@_}, $class;
}

1;
