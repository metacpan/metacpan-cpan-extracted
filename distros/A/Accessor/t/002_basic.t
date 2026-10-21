# -*- perl -*-

# t/002_basic.t - basic Accessor tests

use Test::More tests => 4;

BEGIN { use_ok( 'Accessor' ); }

ok( (sub { new Hash })->(), 'New object' );

ok( (sub { 
	my $obj = new Hash(attr1 => 'foo');
	return $obj->attr1 eq 'foo';
})->(), 'Getting attr' );


ok( (sub { 
	my $obj = new Hash(attr1 => 'foo');
	$obj->attr1('bar');
	return $obj->attr1 eq 'bar';
})->(), 'Setting attr and checking' );




package Hash;

use base 'Accessor';

sub new {
	my $class = shift;
	return bless {@_}, $class;
}

1;
