#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

use strict;
use warnings;

#use utf8;

our $VERSION = '0.05';

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
	# we will connect manually in a bit
	'device-is-connected' => 0,
});
ok(defined($mother), 'Android::ElectricSheep::Automator->new()'." : called and got defined result.") or BAIL_OUT;

my $dp = $mother->find_current_device_properties({
	'force' => 1
});
ok(defined($dp), 'find_current_device_properties()'." : called and got defined result.") or BAIL_OUT;
for my $k ('w', 'h', 'orientation', 'density',
	   'density-x', 'density-y', 'serial'
){
	ok($dp->has($k), 'find_current_device_properties()'." : called and result contains key '$k'.") or BAIL_OUT($dp."\nno, see object above.");
	ok(defined $dp->get($k), 'find_current_device_properties()'." : called and result contains key '$k' and it is defined.") or BAIL_OUT;
}

# now create a new mother with this device

diag $dp;

#diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
 
sleep(1);

