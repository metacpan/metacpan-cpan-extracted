use strict;
use warnings;
use Test::More;
use Test::Method;
use Class::Load 0.20 'load_class';

my $req_prefix = 'Business::PaperlessTrans::Request';
my $prefix     = $req_prefix . 'Part::';


my $address
	= new_ok( load_class( $prefix . 'Address' ) => [{
		street  => '400 E. Royal Lane #201',
		city    => 'Irving',
		state   => 'TX',
		zip     => '75039-2291',
		country => 'US',
	}]);

my $check
	= new_ok( load_class( $prefix . 'Check') => [{
		routing_number  => 111111118,
		account_number  => 12121214,
		name_on_account => 'Richard Simões',
		address         => $address,
	}]);

my $id
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

my $obj
	= new_ok( load_class( $req_prefix . '::ProcessACH' ) => [{
		amount       => 4.22,
		currency     => 'USD',
		check_number => '022',
		check        => $check,
	}]);

can_ok    $obj, 'serialize';
can_ok    $obj, 'type';
method_ok $obj, type => [], 'ProcessACH';

method_ok $obj, serialize => [], {
	Amount       => 4.22,
	Currency     => 'USD',
	CheckNumber  => '022',
	CustomFields => {},
	Check        => {
		RoutingNumber   => '111111118',
		AccountNumber   => '12121214',
		NameOnAccount   => 'Richard Simões',
		Address    => {
			Street  => '400 E. Royal Lane #201',
			City    => 'Irving',
			State   => 'TX',
			Zip     => '75039-2291',
			Country => 'US',
		},
	},
};

done_testing;
