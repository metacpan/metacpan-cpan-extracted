use strict;
use warnings;
use Test::More;
use Module::Runtime qw( use_module );

my $res
	= new_ok( use_module('Business::CyberSource::Response') => [{
		request_id    => '42',
		decision      => 'ACCEPT',
		reason_code   => 100,
		request_token => 'gobbledygook',
	}]);

ok ! $res->can('serialize'), 'can not serialize';
ok ! $res->can('create'),    'can not create';

done_testing;
