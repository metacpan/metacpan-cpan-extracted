use strict;
use warnings;
use Test::More tests => 8;
use Test::NoWarnings;

BEGIN { use_ok('Authen::Radius') };

ok( Authen::Radius->load_dictionary('raddb/dictionary'), 'load dictionary');

is( Authen::Radius::vendorID({Name => 'h323-ivr-out'}), 9, 'Vendor Cisco');
is( Authen::Radius::vendorID({Name => 'User-Name'}), 'not defined', 'No vendor');
is( Authen::Radius::vendorID({Name => 'Cisco-Maximum-Time', Vendor => 'Cisco'}), 9, 'Vendor Cisco');
is( Authen::Radius::vendorID({Name => 'NNN-Attribute', Vendor => 42}), 42, 'Custom Vendor ID');

is( Authen::Radius::vendorID({Name => 'NNN-Attribute'}), 'not defined', 'Unknown attribute');
