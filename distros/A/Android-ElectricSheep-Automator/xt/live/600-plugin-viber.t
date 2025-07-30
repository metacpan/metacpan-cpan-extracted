#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

use strict;
use warnings;

use utf8; # we have unicode strings in here

our $VERSION = '0.06';

use Test::More;
use Test::More::UTF8;
use FindBin;
use Test::TempDir::Tiny;
use Mojo::Log;

use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

use lib ($FindBin::Bin, 'blib/lib');

use Android::ElectricSheep::Automator::Plugins::Apps::Viber;

my $VERBOSITY = 0; # we need verbosity of 10 (max), so this is not used

my $curdir = $FindBin::Bin;

# if for debug you change this make sure that it has path in it e.g. ./xyz
my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $configfile = File::Spec->catfile($curdir, '..', '..', 't', 't-config', 'plugins', 'viber.conf');
ok(-f $configfile, "config file exists ($configfile).") or BAIL_OUT;

my $plugobj = Android::ElectricSheep::Automator::Plugins::Apps::Viber->new({
	'configfile' => $configfile,
	#'verbosity' => $VERBOSITY,
	# we have a device connected and ready to control
	'device-is-connected' => 1,
});
ok(defined($plugobj), 'Android::ElectricSheep::Automator::Plugins::Apps::Viber->new()'." : called and got defined result.") or BAIL_OUT;

# navigate to the home screen, get rid of previous tests rubbish
$plugobj->mother->home_screen();

# open the app
my $res = $plugobj->open_app();
ok(defined($res), 'Android::ElectricSheep::Automator::Plugins::Apps::Viber->open_app()'." : called and got good result.") or BAIL_OUT;
is(ref($res), 'HASH', 'Android::ElectricSheep::Automator::Plugins::Apps::Viber->open_app()'." : called and got good result which is a HASHref.") or BAIL_OUT("no it is '".ref($res)."'");
for my $k (keys %$res){
	is(ref($res->{$k}), 'Android::ElectricSheep::Automator::AppProperties', 'Android::ElectricSheep::Automator::Plugins::Apps::Viber->open_app()'." : called and got good result which is of type 'Android::ElectricSheep::Automator::AppProperties'.") or BAIL_OUT("no it is '".ref($res->{$k})."'");
}
my $appname = $plugobj->appname;

# sleep for a bit
sleep(4);
# check that the app is running
$res = $plugobj->is_app_running();
ok(defined($res), 'Android::ElectricSheep::Automator::Plugins::Apps::Viber->is_app_running()'." : called and got good result.") or BAIL_OUT;
is(ref($res), '', 'Android::ElectricSheep::Automator::Plugins::Apps::Viber->is_app_running()'." : called and got good result which is a SCALAR.") or BAIL_OUT("no it is '".ref($res)."'");
is($res, 1, 'Android::ElectricSheep::Automator::Plugins::Apps::Viber->is_app_running()'." : called and app is running as expected (got result 1).") or BAIL_OUT("no it is not running (got back '$res').");

# now we will have lots of apps but only settings will have AppProperties
my $instantiated_apps = 0;
my @instantiated_apps = ();
my $aregex = qr/\Q${appname}\E/;
my $apps = $plugobj->mother->apps;
for my $appname (sort keys %$apps){
	if( defined $apps->{$appname} ){
		$instantiated_apps++;
		push @instantiated_apps, $appname;
	}
	if( $appname =~ $aregex ){
		ok(defined($apps->{$appname}), 'open_app()'." : app '$appname' has AppProperties.") or BAIL_OUT;
		for my $k (qw/
	 declaredPermissions requestedPermissions
	 installPermissions runtimePermissions enabledComponents
	 usesLibraryFiles usesOptionalLibraries
	 activities MainActivities MainActivity
		/){
			diag "$k:".perl2dump($apps->{$appname}->get($k));
		}
	}
}
is($instantiated_apps, 1, 'open_app()'." : called for regex '$aregex' and result contains one item with AppProperties.") or BAIL_OUT("no it contains ${instantiated_apps} items: ".join(', ', @instantiated_apps));

my $num_apps_total = scalar keys %{ $plugobj->mother->apps };

my $ret = $plugobj->send_message({
	'mock' => 1,
	'outbase' => File::Spec->catfile($tmpdir, 'mytmp'), # save all UI xml got into this basename
	'recipient' => 'My Notes',
	# 1) no unicode, 2) each space must be converted to '%s'
	'message' => 'thank%syou'
});
ok(defined($ret), 'send_message()'." : called and got good result.") or BAIL_OUT;

# close apps

$res = $plugobj->close_app();
ok(defined($res), 'Android::ElectricSheep::Automator::Plugins::Apps::Viber->close_app()'." : called and got good result.") or BAIL_OUT;
is(ref($res), 'HASH', 'Android::ElectricSheep::Automator::Plugins::Apps::Viber->close_app()'." : called and result is a HASHref.") or BAIL_OUT("no it is '".ref($res)."'.");
for my $k (keys %$res){
	is(ref($res->{$k}), 'Android::ElectricSheep::Automator::AppProperties', 'Android::ElectricSheep::Automator::Plugins::Apps::Viber->close_app()'." : called and got good result which is of type 'Android::ElectricSheep::Automator::AppProperties'.") or BAIL_OUT("no it is '".ref($res->{$k})."'");
}

# sleep for a bit
sleep(4);
# check that the app is NOT running
$res = $plugobj->is_app_running();
ok(defined($res), 'Android::ElectricSheep::Automator::Plugins::Apps::Viber->is_app_running()'." : called and got good result.") or BAIL_OUT;
is(ref($res), '', 'Android::ElectricSheep::Automator::Plugins::Apps::Viber->is_app_running()'." : called and got good result which is a SCALAR.") or BAIL_OUT("no it is '".ref($res)."'");
is($res, 0, 'Android::ElectricSheep::Automator::Plugins::Apps::Viber->is_app_running()'." : called and app is running as expected (got result 0).") or BAIL_OUT("no it is not running (got back '$res').");

diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;
# END
done_testing();
 
sleep(1);

