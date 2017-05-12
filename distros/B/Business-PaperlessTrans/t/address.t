use strict;
use warnings;
use Test::More;
use Test::Method;
use Class::Load 0.20 'load_class';

my $prefix = 'Business::PaperlessTrans::RequestPart::';

my $obj
	= new_ok( load_class( $prefix . 'Address' ) => [{
		street  => '400 E. Royal Lane #201',
		city    => 'Irving',
		state   => 'TX',
		zip     => '75039-2291',
		country => 'US',
	}]);

can_ok $obj, 'serialize';

method_ok $obj, serialize => [], {
		Street  => '400 E. Royal Lane #201',
		City    => 'Irving',
		State   => 'TX',
		Zip     => '75039-2291',
		Country => 'US',
};

done_testing;
