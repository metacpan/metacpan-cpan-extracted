use strict;
use warnings;
use Test::More;
use Test::Moose;
use Test::Method;
use Module::Runtime qw( use_module );

my $item
	= new_ok( use_module('Business::CyberSource::RequestPart::Item') => [{
		unit_price => 3.25,
	}]);

does_ok $item, 'MooseX::RemoteHelper::CompositeSerialization';
can_ok  $item, 'serialize';

my %expected_serialized
	= (
		unitPrice => 3.25,
		quantity  => 1,
	);

method_ok $item, unit_price => [], 3.25;
method_ok $item, quantity   => [], 1;
method_ok $item, serialize =>  [], \%expected_serialized;

done_testing;
