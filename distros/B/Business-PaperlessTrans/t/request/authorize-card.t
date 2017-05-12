use strict;
use warnings;
use Test::More;
use Test::Method;
use Class::Load 0.20 'load_class';
use Test::Requires::Env qw( PAPERLESSTRANS_USER PAPERLESSTRANS_PASS );

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
			year  => '2015',
		},
	}]);

my $req
	= new_ok( load_class( $req_prefix . '::AuthorizeCard' ) => [{
		amount       => 9.65,
		currency     => 'USD',
		card         => $card,
		card_present => 0,
	}]);


my $client
	= new_ok( load_class('Business::PaperlessTrans::Client') => [{
		test => 1,
		user => $ENV{PAPERLESSTRANS_USER},
		pass => $ENV{PAPERLESSTRANS_PASS},
	}]);

my $res = $client->submit( $req );

isa_ok $res, 'Business::PaperlessTrans::Response::AuthorizeCard';

method_ok $res, is_approved => [], 1;
method_ok $res, code        => [], 0;
method_ok $res, message     => [], '';

done_testing;
