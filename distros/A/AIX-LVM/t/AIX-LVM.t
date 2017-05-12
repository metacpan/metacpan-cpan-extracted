# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl AIX-LVM.t'

#########################

use Test::More tests => 17;
BEGIN { use_ok('AIX::LVM') };
use AIX::LVM;
#########################

@methods = (
				"get_logical_volume_group",
				"get_physical_volumes",
				"get_logical_volumes",
				"get_volume_group_properties",
				"get_logical_volume_properties",
				"get_physical_volume_properties",
				"get_PV_PP_command",
				"get_PV_LV_command",
				"get_LV_logical_command",
				"get_LV_M_command"
			);
foreach my $meth (@methods) {
    can_ok('AIX::LVM', $meth);
}

SKIP: {
        skip "Environment is not AIX", 6 if $^O!~/aix/i;
        eval {
		  $lvm = new AIX::LVM;
        };
        isa_ok($lvm,"AIX::LVM");
	ok(!$@,"Loaded Module AIX::LVM") or diag("Error is $@") ;
		isa_ok( $lvm, "AIX::LVM" );
		SKIP: {
			skip "Module itself have errors", 3 if $@;
			ok(grep(/rootvg/,$lvm->get_logical_volume_group),"Get Volume Groups");
			ok(scalar($lvm->get_physical_volumes), "Physical Volume Presence");
			ok(scalar($lvm->get_logical_volumes), "Logical Volume Presence");
		}
}

