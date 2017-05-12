use strict;
use warnings;

use Test::More tests => 13;
use Test::Deep;
use FindBin;

use lib $FindBin::Bin. '/../lib';

use_ok q{Amazon::Dash::Button};

my $adb;

$adb = Amazon::Dash::Button->new();
isa_ok $adb, 'Amazon::Dash::Button';

$adb = Amazon::Dash::Button->new( from => {
	# required options
	mac 	=> '00:11:22:33:44:55',
	onClick	=> sub { ... },
	#... optional options
	} );

isa_ok $adb, 'Amazon::Dash::Button';
isa_ok $adb->devices, 'ARRAY';
is scalar @{$adb->devices}, 1, 'element in the devices array';
isa_ok $adb->devices->[0], 'Amazon::Dash::Button::Device';

# ...
#$adb = Amazon::Dash::Button->new( from => 'file.yaml' );

$adb = Amazon::Dash::Button->new()->add(
	mac 	=> '00:11:22:33:44:55',
	onClick	=> sub { ... },
);

isa_ok $adb, 'Amazon::Dash::Button';
isa_ok $adb->devices, 'ARRAY';
is scalar @{$adb->devices}, 1, 'element in the devices array';
isa_ok $adb->devices->[0], 'Amazon::Dash::Button::Device';

note "Chaining devices";

$adb->add( 
	mac 	=> 'aa:11:22:33:44:55',
	onClick	=> sub { ... },
);
is scalar @{$adb->devices}, 2, '2 elements in the devices array';
isa_ok $adb->devices->[0], 'Amazon::Dash::Button::Device';
isa_ok $adb->devices->[1], 'Amazon::Dash::Button::Device';
