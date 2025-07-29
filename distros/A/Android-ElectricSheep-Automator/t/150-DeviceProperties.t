#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

# NOTE: this does checks assuming no device is connected,
# so there is no testing enquire()
# this will be done in livetest

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
use Android::ElectricSheep::Automator::DeviceProperties;

my $VERBOSITY = 0; # we need verbosity of 10 (max), so this is not used

my $curdir = $FindBin::Bin;

my ($params, $sl, $tostring, $xmlfilename);

my $configfile = File::Spec->catfile($curdir, 't-config', 'myapp.conf');
ok(-f $configfile, "config file exists ($configfile).") or BAIL_OUT;

my $mother = Android::ElectricSheep::Automator->new({
	'configfile' => $configfile,
	#'verbosity' => $VERBOSITY,
});
ok(defined($mother), 'Android::ElectricSheep::Automator->new()'." : called and got defined result.") or BAIL_OUT;

$params = {
  'mother' => $mother
};
$sl = Android::ElectricSheep::Automator::DeviceProperties->new($params);
ok(defined($sl), 'Android::ElectricSheep::Automator::DeviceProperties->new()'." : called and got defined result.") or BAIL_OUT;

# must succeed
$params = {
  'mother' => $mother,
  'data' => {
	'w' => 100,
	'h' => 150,
	'orientation' => 0,
	'density' => 420,
	'density-x' => 420.0,
	'density-y' => 420.0,
	'serial' => 'hello',
  }
};
$sl = Android::ElectricSheep::Automator::DeviceProperties->new($params);
ok(defined($sl), 'Android::ElectricSheep::Automator::DeviceProperties->new()'." : called and got defined result.") or BAIL_OUT;

for my $k (sort keys %{$params->{'data'}}){
	my $v = $params->{'data'}->{$k};
	is_deeply($sl->get($k), $v, 'Android::ElectricSheep::Automator::DeviceProperties->new()'." : key '$k' was set to value '".(ref($v)eq''?$v:('['.join(',',@$v).']'))."' OK.") or BAIL_OUT("no it was set to this value instead '".(ref($sl->get($k))eq''?$sl->get($k):('['.join(',',@{$sl->get($k)}).']'))."'.");
}

$tostring = $sl->toString();
ok(defined $tostring, 'toString()'." : called and got good result.") or BAIL_OUT;

diag "Results:\n".$tostring;

diag "Results with operator overloaded:\n".$sl;

#######

# must fail
$params = {
  'mother' => $mother,
  'data' => {
	'w' => [1,1,1,1], # wrong type, this is not a scalar!
	'h' => 150,
	'orientation' => 0,
	'density' => 420,
	'density-x' => 420.0,
	'density-y' => 420.0,
	'serial' => 'hello',
  }
};
$sl = Android::ElectricSheep::Automator::DeviceProperties->new($params);
ok(!defined($sl), 'Android::ElectricSheep::Automator::DeviceProperties->new()'." : called and got defined result.") or BAIL_OUT;

# plain again
$params = {
  'mother' => $mother,
};
$sl = Android::ElectricSheep::Automator::DeviceProperties->new($params);
ok(defined($sl), 'Android::ElectricSheep::Automator::DeviceProperties->new()'." : called and got defined result.") or BAIL_OUT;

$tostring = $sl->toString();
ok(defined $tostring, 'toString()'." : called and got good result.") or BAIL_OUT;

diag "Results with operator overloaded:\n".$tostring;


# END
done_testing();
