use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Method;
use Test::Moose;
use Module::Runtime qw( use_module );
use Test::Requires  qw( NetAddr::IP );

my $billto
	= new_ok( use_module('Business::CyberSource::RequestPart::BillTo') => [{
		first_name  => 'Caleb',
		last_name   => 'Cushing',
		street1     => '8100 Cameron Road',
		street2     => 'Suite B-100',
		city        => 'Austin',
		state       => 'TX',
		postal_code => '78753',
		country     => 'US',
		email       => 'xenoterracide@gmail.com',
		ip          => '192.168.100.2',
	}]);

isa_ok  $billto->ip, 'NetAddr::IP';
does_ok $billto,     'MooseX::RemoteHelper::CompositeSerialization';
can_ok  $billto,     'serialize';

method_ok $billto, first_name  => [], 'Caleb';
method_ok $billto, last_name   => [], 'Cushing';
method_ok $billto, street1     => [], '8100 Cameron Road';
method_ok $billto, street2     => [], 'Suite B-100';
method_ok $billto, city        => [], 'Austin';
method_ok $billto, state       => [], 'TX';
method_ok $billto, country     => [], 'US';
method_ok $billto, email       => [], 'xenoterracide@gmail.com';
method_ok $billto, postal_code => [], '78753';
method_ok $billto->ip, addr    => [], '192.168.100.2';

my %expected_serialized
	= (
		firstName  => 'Caleb',
		lastName   => 'Cushing',
		country    => 'US',
		ipAddress  => '192.168.100.2',
		street1    => '8100 Cameron Road',
		street2    => 'Suite B-100',
		city       => 'Austin',
		state      => 'TX',
		postalCode => '78753',
		email      => 'xenoterracide@gmail.com',
	);

method_ok $billto,  serialize => [], \%expected_serialized;

my $billto1 = new_ok( use_module('Business::CyberSource::RequestPart::BillTo') => [{
	first_name  => 'Caleb',
	last_name   => 'Cushing',
	street1     => '8100 Cameron Road',
	street2     => undef,
	city        => 'Austin',
	state       => 'TX',
	postal_code => '78753',
	country     => 'US',
	email       => 'xenoterracide@gmail.com',
	ip          => '192.168.100.2',
}]);

method_ok $billto1, has_street2 => [], bool(0);

done_testing;
