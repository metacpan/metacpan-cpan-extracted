use strict;
use warnings;
use Test::More;
use Test::Moose;

use Business::CyberSource::Client;
my $class = 'Business::CyberSource::Client';

my $client
	= new_ok( $class => [{
		user => $ENV{PERL_BUSINESS_CYBERSOURCE_USERNAME} || 'test',
		pass => $ENV{PERL_BUSINESS_CYBERSOURCE_PASSWORD} || 'test',
		test => 1,
	}]);

can_ok  $client, qw( name version env );
does_ok $client, 'MooseY::RemoteHelper::Role::Client';

is $client->name, 'Business::CyberSource', "$class->name";

can_ok $client, '_soap_client';

my $soap_client = $client->_soap_client;

is ref $soap_client, 'CODE', 'XML client is a code ref';

my $client1
	= new_ok( $class => [{
		user => $ENV{PERL_BUSINESS_CYBERSOURCE_USERNAME} || 'test',
		pass => $ENV{PERL_BUSINESS_CYBERSOURCE_PASSWORD} || 'test',
		test => 1,
	}]);

my $soap_client1 = $client1->_soap_client;

is ref $soap_client1, 'CODE', 'XML client is a code ref';

done_testing;
