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
use Android::ElectricSheep::Automator::AppProperties;

my $VERBOSITY = 0; # we need verbosity of 10 (max), so this is not used

my $curdir = $FindBin::Bin;

# if for debug you change this make sure that it has path in it e.g. ./xyz
#my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
#ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $configfile = File::Spec->catfile($curdir, '..', '..', 't', 't-config', 'myapp.conf');
ok(-f $configfile, "config file exists ($configfile).") or BAIL_OUT;

my $mother = Android::ElectricSheep::Automator->new({
	'configfile' => $configfile,
	#'verbosity' => $VERBOSITY,
	# we have a device connected and ready to control
	'device-is-connected' => 1,
});
ok(defined($mother), 'Android::ElectricSheep::Automator->new()'." : called and got defined result.") or BAIL_OUT;

my $res = $mother->dump_current_location();
# if we don't have location enabled then this will fail
# just make it a warning and quit silently
if( ! defined $res ){
	diag "this test failed possibly because geo-location is not enabled on the device. The test will stop here but not fail.";
	done_testing();
	exit(0);
} else {
	ok(defined($res), 'Android::ElectricSheep::Automator->dump_current_location()'." : called and got good result.") or BAIL_OUT;
}
# we get a hashref with providers as keys, then each provider
# has lat/lon etc.
is(ref($res), 'HASH', 'Android::ElectricSheep::Automator->dump_current_location()'." : called and got good result.") or BAIL_OUT("no it is '".ref($res)."'.");
for my $aprov (sort keys %$res){
	my $provres = $res->{$aprov};
	for my $k (qw/latitude longitude/){
		ok(exists($provres->{$k}), 'Android::ElectricSheep::Automator->dump_current_location()'." : result contains key '$k' for provider '$aprov'.") or BAIL_OUT(perl2dump($res)."no it does not, see above");
		ok(defined($provres->{$k}), 'Android::ElectricSheep::Automator->dump_current_location()'." : result contains key '$k' and it is defined, for provider '${aprov}'.") or BAIL_OUT(perl2dump($res)."no it does not, see above");
		# some providers may be 'null' meaning no available
		# for those we will have an entry but lat/lon will be <na>
		next if $provres->{$k} eq '<na>';
		ok($provres->{$k}=~/\d+\.\d+/, 'Android::ElectricSheep::Automator->dump_current_location()'." : result contains key '$k' and it validates as a real number, for provider '${aprov}'.") or BAIL_OUT(perl2dump($res)."no it does not, see above");
	}
	for my $k (qw/provider/){
		ok(exists($provres->{$k}), 'Android::ElectricSheep::Automator->dump_current_location()'." : result contains key '$k' for provider '$aprov'.") or BAIL_OUT(perl2dump($res)."no it does not, see above");
		ok(defined($provres->{$k}), 'Android::ElectricSheep::Automator->dump_current_location()'." : result contains key '$k' and it is defined, for provider '${aprov}'.") or BAIL_OUT(perl2dump($res)."no it does not, see above");
	}
}
diag "Current location: ".perl2dump($res);

#diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
 
sleep(1);

