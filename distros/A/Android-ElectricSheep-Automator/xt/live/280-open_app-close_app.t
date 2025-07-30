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

# open an app
my $aregex = qr/^com\.google\.android\.calendar$/i;
my $res = $mother->open_app({
	'package' => $aregex
});
ok(defined($res), 'Android::ElectricSheep::Automator->open_app()'." : called and got good result.") or BAIL_OUT;
is(ref($res), 'HASH', 'Android::ElectricSheep::Automator->open_app()'." : called and got good result which is a HASHref.") or BAIL_OUT("no it is '".ref($res)."'");
for my $k (keys %$res){
	is(ref($res->{$k}), 'Android::ElectricSheep::Automator::AppProperties', 'Android::ElectricSheep::Automator->open_app()'." : called and got good result which is of type 'Android::ElectricSheep::Automator::AppProperties'.") or BAIL_OUT("no it is '".ref($res->{$k})."'");
}

# now we will have lots of apps but only settings will have AppProperties
my $instantiated_apps = 0;
my @instantiated_apps = ();
my $apps = $mother->apps;
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

my $num_apps_total = scalar keys %{ $mother->apps };

sleep(1);

#######################################################
# open another app
$aregex = qr/^com\.google\.android\.deskclock$/i;
$res = $mother->open_app({
	'package' => $aregex
});
ok(defined($res), 'Android::ElectricSheep::Automator->open_app()'." : called and got good result.") or BAIL_OUT;
is(ref($res), 'HASH', 'Android::ElectricSheep::Automator->open_app()'." : called and got good result which is a HASHref.") or BAIL_OUT("no it is '".ref($res)."'");
for my $k (keys %$res){
	is(ref($res->{$k}), 'Android::ElectricSheep::Automator::AppProperties', 'Android::ElectricSheep::Automator->open_app()'." : called and got good result which is of type 'Android::ElectricSheep::Automator::AppProperties'.") or BAIL_OUT("no it is '".ref($res->{$k})."'");
}

# now we will have lots of apps but only settings will have AppProperties
$instantiated_apps = 0;
my @instantiated_apps = (); 
$apps = $mother->apps;
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
is($instantiated_apps, 2, 'open_app()'." : called for regex '$aregex' and result contains one item with AppProperties.") or BAIL_OUT("no it contains ${instantiated_apps} items: ".join(', ', @instantiated_apps));

sleep(1);

# close apps

for $aregex (
	qr/^com\.android\.settings$/i,
	qr/^com\.google\.android\.deskclock$/i,
){
	$res = $mother->close_app({
		'package' => $aregex
	});
	ok(defined($res), 'Android::ElectricSheep::Automator->close_app()'." : called and got good result.") or BAIL_OUT;
	is(ref($res), 'HASH', 'Android::ElectricSheep::Automator->close_app()'." : called and got good result which is a HASHref.") or BAIL_OUT("no it is '".ref($res)."'");
	for my $k (keys %$res){
		is(ref($res->{$k}), 'Android::ElectricSheep::Automator::AppProperties', 'Android::ElectricSheep::Automator->close_app()'." : called and got good result which is of type 'Android::ElectricSheep::Automator::AppProperties'.") or BAIL_OUT("no it is '".ref($res->{$k})."'");
	}
	sleep(2);
}

#diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;
# END
done_testing();
 
sleep(1);

