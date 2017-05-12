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

my $card
	= new_ok( load_class( $prefix . 'Card' ) => [{
		number          => '4012888888881881',
		security_code   => '999',
		name_on_account => 'John Doe and Associates',
		email_address   => 'JohnDoe@TestDomain.com',
		address         => $address,
		identification  => $id,
		expiration      => {
			month => '12',
			year  => '2012',
		},
	}]);

my $obj
	= new_ok( load_class( $req_prefix . '::AuthorizeCard' ) => [{
		amount       => 9.65,
		currency     => 'USD',
		card         => $card,
		card_present => 0,
	}]);

can_ok $obj, 'serialize';

method_ok $obj, serialize => [], {
	Amount       => 9.65,
	Currency     => 'USD',
	CardPresent  => 0,
	CustomFields => {},
	Card         => {
		CardNumber      => '4012888888881881',
		SecurityCode    => '999',
		NameOnAccount   => 'John Doe and Associates',
		EmailAddress    => 'JohnDoe@TestDomain.com',
		ExpirationMonth => '12',
		ExpirationYear  => '2012',
		Identification => {
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
		},
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
