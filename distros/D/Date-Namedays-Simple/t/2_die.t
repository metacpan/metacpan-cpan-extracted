# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 3;

BEGIN { use_ok( 'Date::Namedays::Simple' ); }

my $object = Date::Namedays::Simple->new ();
isa_ok ($object, 'Date::Namedays::Simple');

# do die test

eval {
	$object->processNames();	# this must die, we are calling an abstract method!
};

ok ($@, 'Abstract call dies');
