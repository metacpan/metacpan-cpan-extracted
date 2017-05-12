use strict;
use warnings;
use Test::More;
use Test::Method;
use Class::Load 0.20 'load_class';

my $prefix = 'Business::PaperlessTrans::RequestPart::';

my $address
	= new_ok( load_class( $prefix . 'Address' ) => [{
		street  => '400 E. Royal Lane #201',
		city    => 'Irving',
		state   => 'TX',
		zip     => '75039-2291',
		country => 'US',
	}]);

my $obj
	= new_ok( load_class( $prefix . 'Identification' ) => [{
		id_type    => 1,
		state      => 'TX',
		number     => '12345678',
		address    => $address,
		expiration => {
			day   => 12,
			month => 12,
			year  => 2009,
		},
		date_of_birth => {
			day   => 12,
			month => 12,
			year  => 1965,
		},
	}]);

can_ok $obj, 'serialize';

method_ok $obj, serialize => [], {
	IDType     => 1,
	State      => 'TX',
	Number     => '12345678',
	Expiration => '12/12/2009',
	DOB        => '12/12/1965',
	Address    => {
		Street  => '400 E. Royal Lane #201',
		City    => 'Irving',
		State   => 'TX',
		Zip     => '75039-2291',
		Country => 'US',
	},
};

done_testing;
