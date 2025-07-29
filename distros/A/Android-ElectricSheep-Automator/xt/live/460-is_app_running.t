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
	#'verbosity' => $VERBOSITY,
	# we have a device connected and ready to control
	'device-is-connected' => 1,
});
ok(defined($mother), 'Android::ElectricSheep::Automator->new()'." : called and got defined result.") or BAIL_OUT;

# this app should exist
# we are sure this app exists on a virgin phone i guess?
my $appname = 'com.google.android.calendar';
my $res = $mother->is_app_running({'appname' => $appname});
ok(defined($res), 'Android::ElectricSheep::Automator->is_app_running()'." : called and got good result.") or BAIL_OUT;
is(ref($res), '', 'Android::ElectricSheep::Automator->is_app_running()'." : called and got good result which is a SCALAR.") or BAIL_OUT("no it is '".ref($res)."'");
is($res, 1, 'Android::ElectricSheep::Automator->is_app_running()'." : called and got good result which is 1 meaning the app is running as expected.") or BAIL_OUT("no it is '$res'.");

# this should not exist
# we are sure this app exists on a virgin phone i guess?
my $appname = 'crazy.xxx.yyy.zzz';
my $res = $mother->is_app_running({'appname' => $appname});
ok(defined($res), 'Android::ElectricSheep::Automator->is_app_running()'." : called and got good result.") or BAIL_OUT;
is(ref($res), '', 'Android::ElectricSheep::Automator->is_app_running()'." : called and got good result which is a SCALAR.") or BAIL_OUT("no it is '".ref($res)."'");
is($res, 0, 'Android::ElectricSheep::Automator->is_app_running()'." : called and got good result which is 0, indicating that this app is not running, as expected.") or BAIL_OUT("no it is '$res'.");


#diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
 
sleep(1);

