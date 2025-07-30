#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

use strict;
use warnings;

#use utf8;

our $VERSION = '0.06';

use Test::More;
use Test::More::UTF8;
use FindBin;
use Test::TempDir::Tiny;
use Mojo::Log;

use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

use lib ($FindBin::Bin, 'blib/lib');

use Android::ElectricSheep::Automator;

my $VERBOSITY = 0; # we need verbosity of 10 (max), so this is not used

my $curdir = $FindBin::Bin;

# if for debug you change this make sure that it has path in it e.g. ./xyz
#my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
#ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $configfile = File::Spec->catfile($curdir, '..', '..', 't', 't-config', 'myapp.conf');
ok(-f $configfile, "config file exists ($configfile).") or BAIL_OUT;

my $mother = Android::ElectricSheep::Automator->new({
	'configfile' => $configfile,
	'verbosity' => $VERBOSITY,
});
ok(defined($mother), 'Android::ElectricSheep::Automator->new()'." : called and got defined result.") or BAIL_OUT;
# this mother should not be connected
is($mother->is_device_connected(), 0, 'Android::ElectricSheep::Automator->new()'." : called and device is not connected as expected.") or BAIL_OUT;

# get all devices connected to the desktop
my @devices = $mother->adb->devices;
# and make sure we have at least one device connected to the desktop
ok(scalar(@devices)>0, "there are ".@devices." connected devices on the desktop") or BAIL_OUT("At least one device must be connected to the desktop.");
diag "Found connected android device(s) : ".Android::ElectricSheep::Automator::devices_toString(\@devices);

if( 1 == scalar @devices ){
	# now create a new mother with just the one connected device
	$mother = Android::ElectricSheep::Automator->new({
		'configfile' => $configfile,
		'verbosity' => $VERBOSITY,
		'device-is-connected' => 1,
	});
	ok(defined($mother), 'Android::ElectricSheep::Automator->new()'." : called and got defined result.") or BAIL_OUT;
	# this mother should be connected
	is($mother->is_device_connected(), 1, 'Android::ElectricSheep::Automator->new()'." : called and device is connected as expected.") or BAIL_OUT;
	sleep(1);
	is($mother->disconnect_device(), 0, 'disconnect_device()'." : called and got good result.") or BAIL_OUT;
}

# connect by serial
if( @devices ){
	for my $adev (@devices){
		my $res = $mother->connect_device({'serial' => $adev->serial});
		ok(defined $res, 'connect_device()'." : device set by serial: ".Android::ElectricSheep::Automator::device_toString($adev)) or BAIL_OUT;
		# and disconnect it
		sleep(1);
		$res = $mother->disconnect_device();
		ok(defined $res, 'disconnect_device()'." : device disconnected by serial: ".Android::ElectricSheep::Automator::device_toString($adev)) or BAIL_OUT;
	}
}

# connect by device-object
if( @devices ){
	for my $adev (@devices){
		my $res = $mother->connect_device({'device-object' => $adev});
		ok(defined $res, 'connect_device()'." : device set by device-object: ".Android::ElectricSheep::Automator::device_toString($adev)) or BAIL_OUT;
		# and disconnect it
		sleep(1);
		$res = $mother->disconnect_device();
		ok(defined $res, 'disconnect_device()'." : device disconnected by device-object ".Android::ElectricSheep::Automator::device_toString($adev)) or BAIL_OUT;
	}
}

#diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
 
sleep(1);

