#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

use strict;
use warnings;

#use utf8;

our $VERSION = '0.08';

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
my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;
my $outdir = File::Spec->catdir($tmpdir, 'outapk');

my $configfile = File::Spec->catfile($curdir, '..', '..', 't', 't-config', 'myapp.conf');
ok(-f $configfile, "config file exists ($configfile).") or BAIL_OUT;

my $mother = Android::ElectricSheep::Automator->new({
	'configfile' => $configfile,
	#'verbosity' => $VERBOSITY,
	# we have a device connected and ready to control
	'device-is-connected' => 1,
});
ok(defined($mother), 'Android::ElectricSheep::Automator->new()'." : called and got defined result.") or BAIL_OUT;

my $devobj = $mother->connect_device();
ok(defined($devobj), 'connect_device()'." : called and got good result.") or BAIL_OUT;

# this app should exist
# we are sure this app exists on a virgin phone i guess?
my $appname = qr/gallery/i; # com.android.gallery2
my $sparams = {
	'output-dir' => $outdir,
	'package' => $appname,
	'lazy' => 1,
};
my $res = $mother->pull_app_apk_from_device($sparams);
ok(defined($res), 'Android::ElectricSheep::Automator->pull_app_apk_from_device()'." : called and got good result.") or BAIL_OUT(perl2dump($sparams)."no, it failed, see above params.");
is(ref($res), 'HASH', 'Android::ElectricSheep::Automator->pull_app_apk_from_device()'." : called and got good result which is a HASH_REF.") or BAIL_OUT("no it is '".ref($res)."'");
for my $packagename (sort keys %$res){
  my $arr = $res->{$packagename};
  ok(defined($arr), "got a good entry") or BAIL_OUT(perl2dump($res)."no, it failed, see above result.");
  is(ref($arr), 'ARRAY', "entry is ARRAY_REF.") or BAIL_OUT(perl2dump($res)."no it is '".ref($arr)."', see above result.");
  # all the apks written for this package
  for my $v (@{ $res->{$packagename} }){
	is(ref($v), 'HASH', "result is a HASH_REF") or BAIL_OUT(perl2dump($res)."no it is '".ref($v)."', see return results above.");
	for my $k ('device-path', 'local-path'){
		ok(exists($v->{$k}), "result contains key '$k'.") or BAIL_OUT(perl2dump($v)."no it does not, see return results above.");
		ok(defined($v->{$k}), "result key '$k' has a defined value.") or BAIL_OUT(perl2dump($v)."no it does not, see return results above.");
	}
	ok(-f $v->{'local-path'}, "APK '".$v->{'local-path'}."' exists on disk locally.") or BAIL_OUT;
  }
}
diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
 
sleep(1);
