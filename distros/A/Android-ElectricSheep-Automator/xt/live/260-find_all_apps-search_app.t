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

##############################################################
# find one app by regex name 'calendar' this yields 2 matches
# we expect to have lots of apps but only 2 to be instantiated
#   com.google.android.calendar
#   com.android.providers.calendar
my $aregex = qr/calendar/i;
my $params = {
	'packages' => $aregex, # this will instantiate all matched apps AppProperties
	# default is lazy=1
};
my $apps = $mother->find_installed_apps($params);
ok(defined($apps), 'find_installed_apps()'." : called and got good result.") or BAIL_OUT;
is(ref($apps), 'HASH', 'find_installed_apps()'." : called and result is a HASHref.") or BAIL_OUT("no it is '".ref($apps)."'.");
ok(scalar(keys %$apps)>1, 'find_installed_apps()'." : called and result contains at least one item.") or BAIL_OUT("no it contains ".scalar(keys %$apps)." items.");
is_deeply($apps, $mother->apps, 'find_installed_apps()'." : set mother's apps to the returned value.") or BAIL_OUT;
# now $mother's apps must contain many items but calendar will have AppProperties.
my $instantiated_apps = 0;
my @instantiated_apps = ();
for my $appname (sort keys %$apps){
	if( defined $apps->{$appname} ){
		$instantiated_apps++;
		push @instantiated_apps, $appname;
	}
	if( $appname =~ $aregex ){
		ok(defined($apps->{$appname}), 'find_installed_apps()'." : app '$appname' has AppProperties.") or BAIL_OUT;
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
ok($instantiated_apps==1 || $instantiated_apps==2, 'find_installed_apps()'." : called with regex '$aregex' and result contains one or two items with AppProperties.") or BAIL_OUT("no it contains ${instantiated_apps} items: ".join(', ', @instantiated_apps));
my $num_apps_total = scalar keys %{ $mother->apps };

$params = {
	'package' => $aregex,
	# default is force-reload-apps-list=0
};
my $searched_apps = $mother->search_app($params);
ok(defined($searched_apps), 'search_app()'." : called and got good result") or BAIL_OUT;
is(ref($searched_apps), 'HASH', 'search_app()'." : called and result is a HASHref.") or BAIL_OUT(perl2dump($params)."using above params, no it is '".ref($apps)."'.");
ok(scalar(keys %$searched_apps)==1 || scalar(keys %$searched_apps)==2, 'search_app()'." : called and result contains one or two items.") or BAIL_OUT(perl2dump($params)."using above params, no it contains ".scalar(keys %$searched_apps)." items: ".join(', ', keys %$searched_apps));

# we must still have the same number of total apps in mother
is(scalar keys %{ $mother->apps }, $num_apps_total, "after these operations the number of total apps remains unchanged ($num_apps_total).") or BAIL_OUT(perl2dump($params)."using above params, no it is now ".(scalar keys %{ $mother->apps })." instead of $num_apps_total.");

##############################################################
# find same apps as before with an ARRAY
# we expect to have lots of apps but only 2 to be instantiated
#   com.google.android.calendar
#   com.android.providers.calendar
$aregex = qr/^(\Qcom.google.android.calendar\E)|(\Qcom.android.providers.calendar\E)$/i;
$params = {
	'packages' => [
		'com.google.android.calendar',
		'com.android.providers.calendar'
	],
	# default is lazy=1
};
$apps = $mother->find_installed_apps($params);
ok(defined($apps), 'find_installed_apps()'." : called and got good result.") or BAIL_OUT;
is(ref($apps), 'HASH', 'find_installed_apps()'." : called and result is a HASHref.") or BAIL_OUT(perl2dump($params)."using above params, no it is '".ref($apps)."'.");
ok(scalar(keys %$apps)>1, 'find_installed_apps()'." : called and result contains at least one item.") or BAIL_OUT(perl2dump($params)."using above params, no it contains ".scalar(keys %$apps)." items.");
is_deeply($apps, $mother->apps, 'find_installed_apps()'." : set mother's apps to the returned value.") or BAIL_OUT;
# now $mother's apps must contain many items but calendar will have AppProperties.
my $instantiated_apps = 0;
my @instantiated_apps = ();
for my $appname (sort keys %$apps){
	if( defined $apps->{$appname} ){
		$instantiated_apps++;
		push @instantiated_apps, $appname;
	}
	if( $appname =~ $aregex ){
		ok(defined($apps->{$appname}), 'find_installed_apps()'." : app '$appname' has AppProperties.") or BAIL_OUT;
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
ok($instantiated_apps==1 || $instantiated_apps==2, 'find_installed_apps()'." : called with regex '$aregex' and result contains one or two items with AppProperties.") or BAIL_OUT("no it contains ${instantiated_apps} items: ".join(', ', @instantiated_apps));
my $num_apps_total = scalar keys %{ $mother->apps };

$params = {
	'package' => $aregex,
	# default is force-reload-apps-list=0
};
my $searched_apps = $mother->search_app($params);
ok(defined($searched_apps), 'search_app()'." : called and got good result") or BAIL_OUT;
is(ref($searched_apps), 'HASH', 'search_app()'." : called and result is a HASHref.") or BAIL_OUT(perl2dump($params)."using above params, no it is '".ref($apps)."'.");
ok(scalar(keys %$searched_apps)==1 || scalar(keys %$searched_apps)==2, 'search_app()'." : called and result contains one or two items.") or BAIL_OUT(perl2dump($params)."using above params, no it contains ".scalar(keys %$searched_apps)." items: ".join(', ', keys %$searched_apps));

# we must still have the same number of total apps in mother
is(scalar keys %{ $mother->apps }, $num_apps_total, "after these operations the number of total apps remains unchanged ($num_apps_total).") or BAIL_OUT(perl2dump($params)."using above params, no it is now ".(scalar keys %{ $mother->apps })." instead of $num_apps_total.");

##############################################################
# find same apps as before with a HASH
# we expect to have lots of apps but only 2 to be instantiated
#   com.google.android.calendar
#   com.android.providers.calendar
$aregex = qr/^(\Qcom.google.android.calendar\E)|(\Qcom.android.providers.calendar\E)$/i;
$params = {
	'packages' => {
		'com.google.android.calendar' => 1,
		'com.android.providers.calendar' => 1,
	},
	# default is lazy=1
};
$apps = $mother->find_installed_apps($params);
ok(defined($apps), 'find_installed_apps()'." : called and got good result.") or BAIL_OUT;
is(ref($apps), 'HASH', 'find_installed_apps()'." : called and result is a HASHref.") or BAIL_OUT(perl2dump($params)."using above params, no it is '".ref($apps)."'.");
ok(scalar(keys %$apps)>1, 'find_installed_apps()'." : called and result contains at least one item.") or BAIL_OUT(perl2dump($params)."using above params, no it contains ".scalar(keys %$apps)." items.");
is_deeply($apps, $mother->apps, 'find_installed_apps()'." : set mother's apps to the returned value.") or BAIL_OUT;
# now $mother's apps must contain many items but calendar will have AppProperties.
my $instantiated_apps = 0;
my @instantiated_apps = ();
for my $appname (sort keys %$apps){
	if( defined $apps->{$appname} ){
		$instantiated_apps++;
		push @instantiated_apps, $appname;
	}
	if( $appname =~ $aregex ){
		ok(defined($apps->{$appname}), 'find_installed_apps()'." : app '$appname' has AppProperties.") or BAIL_OUT;
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
ok($instantiated_apps==1 || $instantiated_apps==2, 'find_installed_apps()'." : called with regex '$aregex' and result contains one or two items with AppProperties.") or BAIL_OUT("no it contains ${instantiated_apps} items: ".join(', ', @instantiated_apps));
my $num_apps_total = scalar keys %{ $mother->apps };

$params = {
	'package' => $aregex,
	# default is force-reload-apps-list=0
};
my $searched_apps = $mother->search_app($params);
ok(defined($searched_apps), 'search_app()'." : called and got good result") or BAIL_OUT;
is(ref($searched_apps), 'HASH', 'search_app()'." : called and result is a HASHref.") or BAIL_OUT(perl2dump($params)."using above params, no it is '".ref($apps)."'.");
ok(scalar(keys %$searched_apps)==1 || scalar(keys %$searched_apps)==2, 'search_app()'." : called and result contains one or two items.") or BAIL_OUT(perl2dump($params)."using above params, no it contains ".scalar(keys %$searched_apps)." items: ".join(', ', keys %$searched_apps));

# we must still have the same number of total apps in mother
is(scalar keys %{ $mother->apps }, $num_apps_total, "after these operations the number of total apps remains unchanged ($num_apps_total).") or BAIL_OUT(perl2dump($params)."using above params, no it is now ".(scalar keys %{ $mother->apps })." instead of $num_apps_total.");

#########################################################################
# Now, add one more app, e.g. clock
# find one app by regex name 'clock' this yields 1 match
# we expect to have lots of apps but only 1 to be instantiated
#   com.google.android.deskclock
$aregex = qr/^com\.google\.android\.deskclock$/i;
$params = {
	'packages' => $aregex, # this will instantiate all matched apps AppProperties
	# default is lazy=1
};
$apps = $mother->find_installed_apps($params);
ok(defined($apps), 'find_installed_apps()'." : called and got good result.") or BAIL_OUT;
is(ref($apps), 'HASH', 'find_installed_apps()'." : called and result is a HASHref.") or BAIL_OUT(perl2dump($params)."using above params, no it is '".ref($apps)."'.");
ok(scalar(keys %$apps)>1, 'find_installed_apps()'." : called and result contains at least one item.") or BAIL_OUT(perl2dump($params)."using above params, no it contains ".scalar(keys %$apps)." items.");
is_deeply($apps, $mother->apps, 'find_installed_apps()'." : set mother's apps to the returned value.") or BAIL_OUT;
# now $mother's apps must contain many items but com.android.deskclock.DeskClock will have AppProperties.
$instantiated_apps = 0;
@instantiated_apps = ();
for my $appname (sort keys %$apps){
	if( defined $apps->{$appname} ){
		$instantiated_apps++;
		push @instantiated_apps, $appname;
	}
	if( $appname =~ $aregex ){
		ok(defined($apps->{$appname}), 'find_installed_apps()'." : app '$appname' has AppProperties.") or BAIL_OUT;
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
# note that it contains the instantiated apps previously instantiated, so 2+1 = 3
ok($instantiated_apps==3, 'find_installed_apps()'." : called with regex '$aregex' and result contains three items with AppProperties.") or BAIL_OUT("no it contains ${instantiated_apps} items: ".join(', ', @instantiated_apps));
# we must still have the same number of total apps in mother
is(scalar keys %{ $mother->apps }, $num_apps_total, "after these operations the number of total apps remains unchanged ($num_apps_total).") or BAIL_OUT("no it is now ".(scalar keys %{ $mother->apps })." instead of $num_apps_total.");

$params = {
	'package' => $aregex,
	# default is force-reload-apps-list=0
};
$searched_apps = $mother->search_app($params);
ok(defined($searched_apps), 'search_app()'." : called and got good result") or BAIL_OUT;
is(ref($searched_apps), 'HASH', 'search_app()'." : called and result is a HASHref.") or BAIL_OUT(perl2dump($params)."using above params, no it is '".ref($apps)."'.");
ok(scalar(keys %$searched_apps)==1, 'search_app()'." : called and result contains one or two items.") or BAIL_OUT(perl2dump($params)."using above params, no it contains ".scalar(keys %$searched_apps)." items: ".join(', ', keys %$searched_apps));

# we must still have the same number of total apps in mother
is(scalar keys %{ $mother->apps }, $num_apps_total, "after these operations the number of total apps remains unchanged ($num_apps_total).") or BAIL_OUT(perl2dump($params)."using above params, no it is now ".(scalar keys %{ $mother->apps })." instead of $num_apps_total.");

#########################################################################
# Now, add the same app as above but as a STRING SCALAR
# find one app by regex name 'clock' this yields 1 match
# we expect to have lots of apps but only 1 to be instantiated
#   com.android.deskclock.DeskClock
$aregex = qr/^com\.google\.android\.deskclock$/i;
$params = {
	'packages' => 'com.google.android.deskclock'
	# default is lazy=1
};
$apps = $mother->find_installed_apps($params);
ok(defined($apps), 'find_installed_apps()'." : called and got good result.") or BAIL_OUT;
is(ref($apps), 'HASH', 'find_installed_apps()'." : called and result is a HASHref.") or BAIL_OUT(perl2dump($params)."using above params, no it is '".ref($apps)."'.");
ok(scalar(keys %$apps)>1, 'find_installed_apps()'." : called and result contains at least one item.") or BAIL_OUT(perl2dump($params)."using above params, no it contains ".scalar(keys %$apps)." items.");
is_deeply($apps, $mother->apps, 'find_installed_apps()'." : set mother's apps to the returned value.") or BAIL_OUT;
# now $mother's apps must contain many items but com.android.deskclock.DeskClock will have AppProperties.
$instantiated_apps = 0;
@instantiated_apps = ();
for my $appname (sort keys %$apps){
	if( defined $apps->{$appname} ){
		$instantiated_apps++;
		push @instantiated_apps, $appname;
	}
	if( $appname =~ $aregex ){
		ok(defined($apps->{$appname}), 'find_installed_apps()'." : app '$appname' has AppProperties.") or BAIL_OUT;
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
# note that it contains the instantiated apps previously instantiated, so 2+1 = 3
ok($instantiated_apps==3, 'find_installed_apps()'." : called with regex '$aregex' and result contains three items with AppProperties.") or BAIL_OUT("no it contains ${instantiated_apps} items: ".join(', ', @instantiated_apps));
# we must still have the same number of total apps in mother
is(scalar keys %{ $mother->apps }, $num_apps_total, "after these operations the number of total apps remains unchanged ($num_apps_total).") or BAIL_OUT("no it is now ".(scalar keys %{ $mother->apps })." instead of $num_apps_total.");

$params = {
	'package' => $aregex,
	# default is force-reload-apps-list=0
};
$searched_apps = $mother->search_app($params);
ok(defined($searched_apps), 'search_app()'." : called and got good result") or BAIL_OUT;
is(ref($searched_apps), 'HASH', 'search_app()'." : called and result is a HASHref.") or BAIL_OUT(perl2dump($params)."using above params, no it is '".ref($apps)."'.");
ok(scalar(keys %$searched_apps)==1, 'search_app()'." : called and result contains one or two items.") or BAIL_OUT(perl2dump($params)."using above params, no it contains ".scalar(keys %$searched_apps)." items: ".join(', ', keys %$searched_apps));

# we must still have the same number of total apps in mother
is(scalar keys %{ $mother->apps }, $num_apps_total, "after these operations the number of total apps remains unchanged ($num_apps_total).") or BAIL_OUT(perl2dump($params)."using above params, no it is now ".(scalar keys %{ $mother->apps })." instead of $num_apps_total.");

#########################################################################
# Now, add one more app, e.g. settings
# find one app by regex name 'settings' this yields 1 match
# but because lazy is 0 we expect all to have AppProperties instantiated
#   com.android.providers.settings
$aregex = qr/^com\.android\.settings/i; # weirdly the exact com.android.settings does not exist!!! sometimes
$params = {
	'packages' => $aregex, # this will instantiate all matched apps AppProperties
	# this will instantiate all apps
	'lazy' => 0,
};
$apps = $mother->find_installed_apps($params);
ok(defined($apps), 'find_installed_apps()'." : called and got good result.") or BAIL_OUT;
is(ref($apps), 'HASH', 'find_installed_apps()'." : called and result is a HASHref.") or BAIL_OUT(perl2dump($params)."using above params, no it is '".ref($apps)."'.");
ok(scalar(keys %$apps)>1, 'find_installed_apps()'." : called and result contains at least one item.") or BAIL_OUT(perl2dump($params)."using above params, no it contains ".scalar(keys %$apps)." items.");
is_deeply($apps, $mother->apps, 'find_installed_apps()'." : set mother's apps to the returned value.") or BAIL_OUT;
# now $mother's apps must contain many items but calendar will have AppProperties.
$instantiated_apps = 0;
@instantiated_apps = ();
for my $appname (sort keys %$apps){
	if( defined $apps->{$appname} ){
		$instantiated_apps++;
		push @instantiated_apps, $appname;
	}
	if( $appname =~ $aregex ){
		ok(defined($apps->{$appname}), 'find_installed_apps()'." : app '$appname' has AppProperties.") or BAIL_OUT;
		if(0){
		# don't print them because lazy=0, they will be all apps
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
}
is($instantiated_apps, $num_apps_total, 'find_installed_apps()'." : called with regex '$aregex' and result contains one or two items with AppProperties.") or BAIL_OUT("no it contains ${instantiated_apps} items: ".join(', ', @instantiated_apps));
# we must still have the same number of total apps in mother
is(scalar keys %{ $mother->apps }, $num_apps_total, "after these operations the number of total apps remains unchanged ($num_apps_total).") or BAIL_OUT("no it is now ".(scalar keys %{ $mother->apps })." instead of $num_apps_total.");

$params = {
	'package' => $aregex,
	# default is force-reload-apps-list=0
};
$searched_apps = $mother->search_app($params);
ok(defined($searched_apps), 'search_app()'." : called and got good result") or BAIL_OUT;
is(ref($searched_apps), 'HASH', 'search_app()'." : called and result is a HASHref.") or BAIL_OUT(perl2dump($params)."using above params, no it is '".ref($apps)."'.");
ok(scalar(keys %$searched_apps)>0, 'search_app()'." : called and result contains one or two items.") or BAIL_OUT(perl2dump($params)."using above params, no it contains ".scalar(keys %$searched_apps)." items: ".join(', ', keys %$searched_apps));

# we must still have the same number of total apps in mother
is(scalar keys %{ $mother->apps }, $num_apps_total, "after these operations the number of total apps remains unchanged ($num_apps_total).") or BAIL_OUT(perl2dump($params)."using above params, no it is now ".(scalar keys %{ $mother->apps })." instead of $num_apps_total.");

#diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing();
 
sleep(1);

