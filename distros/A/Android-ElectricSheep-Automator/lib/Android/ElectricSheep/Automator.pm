package Android::ElectricSheep::Automator;

# see also https://www.reddit.com/r/privacytoolsIO/comments/fit0tr/taking_almost_full_control_of_your_unrooted/
# swipe adb shell input touchscreen swipe 300 1200 100 1200 100

use 5.006;
use strict;
use warnings;

our $VERSION = '0.05';

use Mojo::Log;
use Config::JSON::Enhanced;
# it requires v0.002 (which is with my modifications)
#use Android::ADB;
# issue filed for Android::ADB :
#   https://rt.cpan.org/Public/Bug/Display.html?id=163391
# until this is resolved I am copying Android::ADB
# into my distribution, fixing the issues and renaming it to
# Android::ElectricSheep::Automator::ADB
# and using that. When the issue is resolved I will go back
# using Android::ADB
# Credits for Android::ADB (now Android::ElectricSheep::Automator::ADB)
# go to Marius Gavrilescu (marius@ieval.ro)
# as seen in:
#   https://metacpan.org/pod/Android::ADB
#
use Android::ElectricSheep::Automator::ADB;
use File::Temp qw/tempfile/;
use Cwd;
use FindBin;
use Time::HiRes qw/usleep/;
use Image::PNG;
use XML::LibXML;
use XML::LibXML::XPathContext;
use Text::ParseWords;

use Data::Roundtrip qw/perl2dump perl2json no-unicode-escape-permanently/;

use Android::ElectricSheep::Automator::DeviceProperties;
use Android::ElectricSheep::Automator::AppProperties;
use Android::ElectricSheep::Automator::ScreenLayout;
use Android::ElectricSheep::Automator::XMLParsers;

my $_DEFAULT_CONFIG = <<'EODC';
</* $VERSION = '0.05'; */>
</* comments are allowed */>
</* and <% vars %> and <% verbatim sections %> */>
{
	"adb" : {
		"path-to-executable" : "/usr/local/android-sdk/platform-tools/adb"
	},
	"debug" : {
		"verbosity" : 0,
		</* cleanup temp files on exit */>
		"cleanup" : 1
	},
	"logger" : {
		</* log to file if you uncomment this */>
		</* "filename" : "..." */>
	}
	</* config for our plugins (each can go to separate file also) */>
}
EODC

# NOTE: by default, it assumes that no device is connected
# and so it does not enquire about screen size etc on startup
# In order to tell it that a device (just one)
# is connected to the desktop and that we should connect to
# it, 
#   use param 'device-is-connected' => 1
# if there are more than one devices and you want to connect to
# one of them, then 
#  use param 'device-serial' => <serial-of-device-to-connect>
# or
#  use param 'device-object' => <device object>
#        (of type Android::ElectricSheep::Automator::ADB::Device)
# or after instantiation with $obj->connect_device(...);
# and similarly for disconnect_device()
# NOTE: without connecting to a device you can not use e.g. open_app(), swipe() etc.
sub new {
	my $class = ref($_[0]) || $_[0]; # aka proto
	my $params = $_[1] // {};

        my $parent = ( caller(1) )[3] || "N/A";
        my $whoami = ( caller(0) )[3];

	my $self = {
		'_private' => {
			'confighash' => undef,
			'configfile' => '', # this should never be undef
			'Android::ADB' => undef,
			'debug' => {
				'verbosity' => 0,
				'cleanup' => 1,
			},
			'log' => {
				'logger-object' => undef,
				'logfile' => undef
			},
		},

		# object of type Android::ElectricSheep::Automator::DeviceProperties
		# if this is undef, then it means caller did not call connect_device()
		# when caller calls disconnect_device(), this becomes undef again
		# this is a cheap way to not proceed to device-needed subs, e.g. swipe()
		# of course we could make an adb query with e.g. adb get-state
		'device-properties' => undef,

		# object of type Android::ElectricSheep::Automator::ADB::Device
		# which is created when we call connect_device()
		'device-object' => undef,

		# a hash of installed apps by package name (e.g. android.google.calendar)
		# the value will be an AppProperties object if it was enquired or undef
		# if it wasn't. As the addition of apps is done in a lazy way, when
		# needed, unless specified otherwise. In any event open_app() will add an
		# AppProperties object if missing to the specified package.
		'apps' => {},

		# legacy, no worries.
		'apps-roundabout-way' => undef,
	};
	bless $self => $class;

	# this will read configuration and create confighash,
	# make logger, verbosity,
	# instantiate any objects we need here etc.
	if( $self->init($params) ){ print STDERR __PACKAGE__."${whoami} (via $parent), line ".__LINE__." : error, call to init() has failed.\n"; return undef }

	# Now we have a logger
	my $log = $self->log();

	# do module-specific init
	if( $self->init_module_specific($params) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to init_module_specific() has failed."); return undef }

	# optional params, defaults exist above or in the configfile
	if( exists($params->{'verbosity'}) && defined($params->{'verbosity'}) ){ $self->verbosity($params->{'verbosity'}) } # later we will call verbosity()
	if( exists($params->{'cleanup'}) && defined($params->{'cleanup'}) ){ $self->cleanup($params->{'cleanup'}) }
	else { $self->cleanup($self->confighash->{'debug'}->{'cleanup'}) }

	my $verbosity = $self->verbosity;

	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : done, success (verbosity is set to ".$self->verbosity." and cleanup to ".$self->cleanup.").") }

	return $self;
}

# This signals our object that there is at least one device connected
# to the desktop which ADB can access and so can we.
# set the device by specifying one of
#  'serial' : the device's serial
#  'device-object' : a Android::ADB::Device object
#     as returned by any item of $self->adb->devices()
# However, if there is ONLY ONE device connected to the desktop, then
# you do not need to specify a device, use this method without arguments
#
# It returns the device object (Android::ADB::Device) on success
# or undef on failure
sub connect_device {
	my ($self, $params) = @_;
	$params //= {};

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $log = $self->log();
	my $verbosity = $self->verbosity;

	my ($what_device, $m);

	if( exists($params->{'serial'}) && defined($m=$params->{'serial'}) ){
		my $devs = $self->devices();
		
		for (@$devs){
			if( $_->serial eq $m ){ $what_device = $_; last }
		}
		if( ! defined $what_device ){ $log->error(devices_toString($devs)."\n${whoami} (via $parent), line ".__LINE__." : error, there is no device with specified serial '$m', above are all the connected devices."); return undef }
	} elsif( exists($params->{'device-object'}) && defined($m=$params->{'device-object'})
	      && (ref($params->{'device-object'})eq'Android::ElectricSheep::Automator::ADB::Device')
	){
		$what_device = $m
	} else {
		# no params means we assume there is exactly 1 device connected to the desktop
		my $devs = $self->devices();
		if( scalar(@$devs) == 1 ){
			$what_device = $devs->[0];
		} else { $log->error("${whoami} (via $parent), line ".__LINE__." : error, expecting exactly one device connected to the desktop but found ".scalar(@$devs)." instead. In the case of more than one devices connected to the desktop then specify which one you want to target by using parameter 'serial' or 'device-object'. If no devices are connected then connect one to the desktop first."); return undef }
	}

	# this can die
	my $res = eval { $self->adb->set_device($what_device) };
	if( $@ || ! defined $res ){ $log->error(device_toString($what_device)."\n${whoami} (via $parent), line ".__LINE__." : error, call to ".'adb->set_device()'." has failed for above device."); return undef }

	# and get the device properties of the set device
	# that method will also set $self->{'device-properties'} to the returned object
	my $device_properties = $self->find_current_device_properties();
	if( ! defined $device_properties ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'find_current_device_properties()'." has failed."); return 1; }

	$self->{'device-object'} = $what_device;

	return $what_device; # Android::ADB::Device object
}

sub devices_toString { join("\n", map { device_toString($_) } @{$_[0]}) }
sub device_toString { join('/', $_[0]->serial, $_[0]->product, $_[0]->model, $_[0]->device) }

# returns the device properties object
# use $self->device_properties->get('w') to get or ->set('w', 12) to set.
sub device_properties { return $_[0]->{'device-properties'} }

# it dumps the current screen UI as XML and returns that as a scalar string,
# optionally saving it to the specified file
# It returns undef on failure.
# On success, it returns a hash with 2 keys:
#   'raw' : contains the raw XML content (as a string)
#   'XML::LibXML' : contains an XML::LibXML object with the parsed
#                  XML string, ready to do XPath queries
# it needs that connect_device() to have been called prior to this call
sub dump_current_screen_ui {
	my ($self, $params) = @_;

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $log = $self->log();
	my $verbosity = $self->verbosity;

	if( ! $self->is_device_connected() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, you need to connect a device to the desktop and ALSO explicitly call ".'device_connected()'." before calling this."); return undef }

	my $filename = exists($params->{'filename'}) && defined($params->{'filename'}) ? $params->{'filename'} : undef;

	my $FH;
	if( ! defined $filename ){
		($FH, $filename) = tempfile(CLEANUP=>$self->cleanup);
		close $FH;
	}
	# WARNING, you need to wake up the phone before dumping !!!!
	my $devicefile = File::Spec->catfile('/', 'data', 'local', 'tmp', $$.'.xml');

	my (@cmd, $res);

	my $maxiters = 7;
	WMA:
	while( $maxiters-- > 0 ){
		@cmd = ('uiautomator', 'dump', $devicefile);
		if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : maxiters $maxiters : sending command to adb: @cmd") }
		my $res = $self->adb->shell(@cmd);
		if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return undef }
		if( $res->[0] != 0 ){ $log->error("--begin result:\n".perl2dump($res)."--end result.\n--begin command:\n".join(" ", @cmd)."\n--end command.\n\n"."${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return undef }

		# check twice with a sleep if the dump is there, else
		# we are repeating the previous command to dump the ui
		for(1..2){
			# now check if the dump file is there, sometimes it is not. repeat if not
			if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : maxiters $maxiters : in order to find if the uiautomator dump succeeded : sending command to adb: @cmd") }
			@cmd = ('if', '[', '-f', $devicefile, ']', ';', 'then', 'echo', 'found', ';', 'else', 'echo', 'notfound', ';', 'fi');
			$res = $self->adb->shell(@cmd);
			if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return undef }
			if( $res->[0] != 0 ){ $log->error("--begin result:\n".perl2dump($res)."--end result.\n--begin command:\n".join(" ", @cmd)."\n--end command.\n\n"."${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return undef }
			if( $res->[1] =~ /^found/ ){
				if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : maxiters $maxiters : found the dump file '$devicefile' on device, stopping the loop.") }
				last WMA
			} else { if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : maxiters $maxiters : DID NOT FIND the dump file '$devicefile' on device, continue the loop until iters reach 0.") } }
			usleep(0.5);
		}
	}
	# This may fail because above dump sometimes fails, no error
	# just not producing any output file. If this persists we
	# can try dumping to stdout.

	# pull the output
	$res = $self->adb->pull($devicefile, $filename);
	if( ! defined $res ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to pull remote file '$devicefile' into local file '$filename', because undefined was returned, this should not be happening."); return undef }
	if( $res->[0] != 0 ){ $log->error("--begin result:\n".perl2dump($res)."--end result.\n"."${whoami} (via $parent), line ".__LINE__." : error, failed to pull remote file '$devicefile' into local file '$filename' with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return undef }

	# remove the device file
	@cmd = ("rm", "-f", $devicefile);
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : sending command to adb: @cmd") }
	$res = $self->adb->shell(@cmd);
	if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return undef }
	if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return undef }

	# let's return the string content back
	my $contents;
	if( ! open($FH, '<', $filename) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to open file with dump for reading '$filename', $!"); return undef }
	{ local $/ = undef; $contents = <$FH> } close $FH;

	my $retxmlobj = XML::LibXML->load_xml(string => $contents);
	if( ! defined $retxmlobj ){ $log->error("${contents}\n${whoami} (via $parent), line ".__LINE__." : error, failed to parse above XML content."); return undef }
	my $xc = XML::LibXML::XPathContext->new($retxmlobj);
	$xc->registerFunction('matches', \&Android::ElectricSheep::Automator::XMLParsers::xpath_matches);
	return {
		'raw' => $contents,
		'XML::LibXML' => $retxmlobj,
		'XML::LibXML::XPathContext' => $xc
	}
}

# return an ARRAYref of all connected devices. This array can be empty if none is connected
# but an arrayref is definetely returned.
sub devices {
	my $self = $_[0];
	my @devs = $self->adb->devices();
	return \@devs;
}

# It returns 0 on success, 1 on failure.
# It swipes the screen as per the 'direction'
# or full spec (x1,y1,x2,y2) (e.g. from x1 to x2 etc.)
# optional parameter 'dt' is the milliseconds to take for the swipe
# small is fast. Some speed is needed for certain gestures, so
# this is important parameter. E.g. for swiping to another screen.
# it needs that connect_device() to have been called prior to this call
sub swipe {
	my ($self, $params) = @_;
	$params //= {};

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	if( ! $self->is_device_connected() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, you need to connect a device to the desktop and ALSO explicitly call ".'connect_device()'." before calling this."); return 1 }

	my $w = $self->device_properties->get('w');
	my $h = $self->device_properties->get('h');

	my @fullspec;
	for ('x1', 'y1', 'x2', 'y2', 'dt'){
		if( ! exists($params->{$_}) || ! defined($params->{$_}) ){ last }
		push @fullspec, $params->{$_};
	}
	my @cmd;
	if( scalar(@fullspec) == 4 ){
		if( ($params->{'x1'} < 0) || ($params->{'x1'} > $w) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, input parameter 'x1' has a value (".$params->{'x1'}.") which is out of bounds."); return 1 }
		if( ($params->{'y1'} < 0) || ($params->{'y1'} > $h) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, input parameter 'y1' has a value (".$params->{'y1'}.") which is out of bounds."); return 1 }
		if( ($params->{'x2'} < 0) || ($params->{'x2'} > $w) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, input parameter 'x2' has a value (".$params->{'x2'}.") which is out of bounds."); return 1 }
		if( ($params->{'y2'} < 0) || ($params->{'y2'} > $h) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, input parameter 'y2' has a value (".$params->{'y2'}.") which is out of bounds."); return 1 }
		@cmd = ('input', 'touchscreen', 'swipe', @fullspec);
	} else {
		# the time to do the move in milliseconds, there is a default of 100
		# which is enough to swipe to next screen
		my $dt = (exists($params->{'dt'}) && defined($params->{'dt'})) ? $params->{'dt'} : 100;
		my $direction = (exists($params->{'direction'}) && defined($params->{'direction'})) ? $params->{'direction'} : undef;
		if( ! defined $direction ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, input parameter 'direction' was not specified."); return 1 }

		my ($x1, $y1, $x2, $y2);

		if( ($direction =~ /^l(eft)?$/i) || ($direction =~ /^r(ight)?$/i) ){
			# horizontal
			$y1 = $y2 = int(3*$h/4);
		} else {
			# vertical
			$x1 = $x2 = int($w/2);
		}
		if( ($direction =~ /^r(ight)?$/i) ){
			$x1 = int(0.2*$w);
			$x2 = $w - $x1;
		}
		if( ($direction =~ /^l(eft)?$/i) ){
			$x2 = int(0.2*$w);
			$x1 = $w - $x2;
		}
		if( ($direction =~ /^d(own)?$/i) ){
			$y1 = int(0.2*$h);
			$y2 = $h - $y1;
		}
		if( ($direction =~ /^u(p)?$/i) ){
			$y2 = int(0.2*$h);
			$y1 = $h - $y2;
		}
		@cmd = ('input', 'touchscreen', 'swipe', $x1, $y1, $x2, $y2, $dt);
	}

	# unfortunately Android::ADB uses IPC::Open2::open2() to run the adb shell command
	# which does not capture STDERR, and so either they use open3 or we capture stderr thusly:

	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : sending command to adb: @cmd") }
	my $res = $self->adb->shell(@cmd);
	if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return undef }
	if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return undef }

	return 0; # success
}

# It finds all installed apps on device and appends with
# earlier results in $self->apps, and returns them as a hash
# keyed on appname. It also saves the returned hash into $self->apps
# optionally erasing previous entries (if 'make-fresh-apps-list'==1)
# The big question is whether to enquire the device for each package (app)
# installed and create an AppProperties object for each or not.
# The former is expensive and so you can do it on if-and-when-needed-basis
# (lazily). Or you can do it all at once here, it takes like 10-20 seconds.
# In any way, lazy or not, at the end the $self->apps HASH will be filled
# with the names of all packages installed on device (key).
# If 'lazy'==0, then for each installed app the device will be enquired
# and an AppProperties object will be created (it contains MainActivity,
# Permissions, etc.) and set as the value in the apps HASH.
# If 'packages' is specified and 'lazy'==0, then only those packages
# in 'packages' will be enquired, the $self->apps list will be
# refreshed with all the package names (key) but only some of them will
# contain an AppProperties object as the value, the other values
# will be undef.
# If no 'packages' was specified and 'lazy'==0, then all
# packages installed on device will be enquired and an AppProperties object
# will be associated with each of them in $self->apps.
# Default 'lazy' value is 1.
# Input:
#   'packages' => 'packagename' or regex (e.g. qr//) or [...] or { ...} :
#       optionally specify a list of package names to find ONLY,
#       default is to find ALL apps, which can be expensive if lazy>0
#       the 'packages' items can be a scalar string for exact match
#       or a compiled regex (qr//)
#   'force-reload-apps-list' => 0 or 1 : if 1, erase current list and start afresh
#   'lazy' => 1 or 0 : optionally specify not to enquire each package in detail,
#       i.e. creating an AppProperties object for each package,
#       but just add the package name as a key to the hash,
#       leaving the value undef. This value will be
#       created when needed, e.g. in an open_app() call.
#       Default is to be lazy, 1.
# It needs that connect_device() to have been called prior to this call
#
# On failure it returns undef.
# On success it saves the results in $self->apps HASH and returns that.
#
# NOTE: enquiring installed apps entails this:
#  1. adb shell dumpsys package packages
#     which is a general output of installed packages but does not contain
#     activity information.
#  2. For a given installed app name (package) we enquire by
#       adb shell dumpsys package com.example.myapp
#  WARNING: the 2nd step if called for all the installed apps can take some
#           time as it is done for each installed app.
#           Perhaps a better approach is to lazily find apps by
#           specifying the name of the app with the input parameter
#             'packages' => [...]
#           This will append to apps() the result.
sub find_installed_apps {
	my ($self, $params) = @_;
	$params //= {};

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	if( ! $self->is_device_connected() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, you need to connect a device to the desktop and ALSO explicitly call ".'connect_device()'." before calling this."); return undef }

	# optionally caller can specify a list of app names to enquire
	# either as exact package name (string), a Regexp object (qr//)
	# an ARRAY of package names or a HASH of package names:
	my $packages = exists($params->{'packages'}) && defined($params->{'packages'}) ? $params->{'packages'} : undef;
	my $rr = ref $packages;
	if( ($rr ne '')&&($rr ne 'Regexp')&&($rr ne 'ARRAY')&&($rr ne 'HASH') ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, the type of input parameter 'packages' must be one of scalar string, Regexp, ARRAY or HASH and not '$rr'."); return undef }

	# NOTE: that all those 'packages', if any,
	# will be non-lazily even if 'lazy' is 1
	# omit 'packages' and you will have all packages according to the 'lazy' param
	# Also even if 'packages' is specified, the list of ALL apps will
	# be saved in the hash, except that those not in 'packages' will have
	# undef value and the others will have an AppProperties object value.
	my $epars = {
		'mother' => $self,
		('packages' => $params->{'packages'})x!!(exists($params->{'packages'}) && defined($params->{'packages'})),
		('lazy' => $params->{'lazy'})x!!(exists($params->{'lazy'}) && defined($params->{'lazy'})),
	};
	my $apps = Android::ElectricSheep::Automator::AppProperties::enquire_installed_apps_factory($epars);
	if( ! defined $apps ){ $epars->{'mother'} = '<redacted>'; $log->error(perl2dump($epars)."${whoami} (via $parent), line ".__LINE__." : error, failed to find all installed apps, call to ".'Android::ElectricSheep::Automator::AppProperties::enquire_installed_apps_factory()'." has failed."); return undef }

	# erase the current list before adding?
	$self->{'apps'} = {} if exists($params->{'make-fresh-apps-list'})
			     && defined($params->{'make-fresh-apps-list'})
			     && ($params->{'make-fresh-apps-list'}>0)
	;

	# we will append to our apps list, which could have just been emptied
	# but if there is a key with AppProperties value
	# (and now it has undef) then we will keep that value instead of undef:
	for my $k (keys %$apps){
		next if exists($self->{'apps'}->{$k})
		     && defined($self->{'apps'}->{$k})
		;
		$self->{'apps'}->{$k} = $apps->{$k};
	}
	#my @k = keys %$apps; @{ $self->{'apps'} }{@k} = @{ $apps }{@k};

	return $self->apps; # success
}

# searches the current list of installed apps in $self->{'apps'}
# for the input app name or name regex.
# Note that a call to find_installed_apps() will populate
# the $self->{'apps'} with the keys (package names)
# but the expensive query for each and every key (package name)
# will be done lazily on a if-and-when-needed-basis
# but ALL the package names exist in $self->apps.

# Inputs parameters:
#   'package' => required package name as a SCALAR (for an exact search)
#     or a regex (qr//) object for regex search including case-insensitive.
#   'force-reload-apps-list' => 0,1 : optionally call find_installed_apps() if > 0
#     but restricted only to the packages match 'package' NOT ALL.
#   'lazy' => 0,1 : pass this lazy value to the find_installed_apps()
#     and be lazy (i.e. without enquiring on each app's specifics
#     and creating an AppProperties object) if ==1
#     or not be lazy if ==0 ...
#     ... (which means an AppProperties object is created for EACH package in the device)
#     Default is force-reload-apps-list=>0
# It returns the found packages (full package name (which is a key in $self->{'apps'}))
# as a HASHref if any found, or {} if none found.
# the key to the returned hash is the full package name and the value
# will be AppProperties object or undef if not instantiated for that app
# because of lazy=1
# It returns undef on failure.
sub search_app {
	my ($self, $params) = @_;
	$params //= {};

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	my $package;
	if( ! exists($params->{'package'}) || ! defined($package=$params->{'package'}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, input parameter 'package' was not specified, it must be a package name or a compiled regex (e.g. via ".'qr//'.") for searching a package name in the list of installed apps."); return undef }
	if( (ref($package)ne'') && (ref($package)ne'Regexp') ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, the type of input parameter 'package' must be a scalar string (the package name) or a Regexp object (compiled regex via ".'qr//'.")."); return undef }

	my $force_reload = (exists($params->{'force-reload-apps-list'}) && defined($params->{'force-reload-apps-list'})) ? $params->{'force-reload-apps-list'} : 0;
	my $lazy = (exists($params->{'lazy'}) && defined($params->{'lazy'})) ? $params->{'lazy'} : 1;

	my $apps = $self->apps();
	# if we have no apps list or we have a force reload, then
	if( (0 == scalar(keys %$apps))
	 || ($force_reload>0)
	){
		my $fpars = {
			'packages' => $package,
			'force-reload-apps-list' => $force_reload,
			'lazy' => $lazy
		};
		if( ! defined($apps=$self->find_installed_apps($fpars)) ){ $log->error(perl2dump($fpars)."${whoami} (via $parent), line ".__LINE__." : error, failed to load list of installed apps, call to ".'find_installed_apps()'." has failed with above parameters."); return undef }
		if( 0 == scalar(keys %$apps) ){
			$log->error("${whoami} (via $parent), line ".__LINE__." : error, there are no installed apps, even after enquiring them. The target device has no apps installed. Weird.");
			return undef
		}
	}

	# we have a package name, so return if if found
	if( ref($package) eq '' ){
		# a scalar string : exact match of a package name
		return exists($apps->{$package})
			? { $package => $apps->{$package} }
			: {}
		;
	}

	# we have a regex contained in package name,
	# return those matched:
	return { map { $_ => $apps->{$_} }
		 grep { $_ =~ $package }
		 sort keys %$apps
	};
}

# It searches the process table (using pidof) for the
# specified app name to check if it is running.
# Inputs parameters:
#   'appname' => an exact app name to find if it is running
# It returns 1 if the specified app is running, 0 if it is not
# It returns undef on failure.
sub is_app_running {
	my ($self, $params) = @_;
	$params //= {};

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	my $appname;
	if( ! exists($params->{'appname'}) || ! defined($appname=$params->{'appname'}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, input parameter 'appname' was not specified. It can be an exact app name or an extended regular expression which Android's pgrep understands."); return undef }

	my $res = $self->pidof({'name' => $appname});
	if( ! defined $res ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'pidof()'." has failed."); return undef }

	# it returns undef on failure
	# it returns -1 if it is not found in the process table
	# it retuns >0 as the pid of the running app
	#if( $res == -1 ){ return 0 } # no it is not running
	if( $res =~ /^\d+$/ ){ return 1 } # yes it is running
	return 0; # no it is not running
}

# Inputs parameters:
#   'package' : required package name as a SCALAR (for an exact search)
#     or a regex (qr//) object for regex search including case-insensitive.
#    'activity' : optional activity name to start additionally to the app/package name.
#     If not present, we will try to find the MAIN activities of the package via
#     AppProperties. There could be several MAIN activities and there are heuristics
#     to pick one. See AppProperties::enquire().
#     The spec must yield exactly 1 match, it will complain if more than 1 matches found.
#   'force-reload-apps-list' => 0,1 : optionally call find_installed_apps() if > 0
#     but restricted only to the packages match 'package' NOT ALL.
#   'lazy' => 0,1 : pass this lazy value to the find_installed_apps()
#     and be lazy (i.e. without enquiring on each app's specifics
#     and creating an AppProperties object) if ==1
#     or not be lazy if ==0 ...
#     ... (which means an AppProperties object is created for each found package)
#     Default is force-reload-apps-list=>0
#     THIS APPLIES ONLY TO THE MATCHED 'package'
# On success it returns a hash of {appname => appproperties} of the opened app
#    (which will be created if not existing). It may return {} if no match
#    was found for the specified 'package' name.
# On failure it returns undef
# it needs that connect_device() to have been called prior to this call
sub open_app {
	my ($self, $params) = @_;
	$params //= {};

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	if( ! $self->is_device_connected() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, you need to connect a device to the desktop and ALSO explicitly call ".'connect_device()'." before calling this."); return undef }

	my ($package);
	if( ! exists($params->{'package'}) || ! defined($package=$params->{'package'}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, input parameter 'package' is required."); return undef }
	if( (ref($package)ne'') && (ref($package)ne'Regexp') ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, the type of input parameter 'package' must be a scalar string (the package name) or a Regexp object (compiled regex via ".'qr//'.")."); return undef }

	# optional activity, else we will see if we find one
	my $activity = (exists($params->{'activity'}) && defined($params->{'activity'})) ? $params->{'activity'} : undef;

	my $force_reload = (exists($params->{'force-reload-apps-list'}) && defined($params->{'force-reload-apps-list'})) ? $params->{'force-reload-apps-list'} : 0;
	my $lazy = (exists($params->{'lazy'}) && defined($params->{'lazy'})) ? $params->{'lazy'} : 1;

	my $apps = $self->apps();
	if( (0 == scalar(keys %$apps))
	 || ($force_reload>0)
	){
		my $fpars = {
			'packages' => $package,
			'force-reload-apps-list' => $force_reload,
			'lazy' => $lazy
		};
		if( ! defined($apps=$self->find_installed_apps($fpars)) ){ $log->error(perl2dump($fpars)."${whoami} (via $parent), line ".__LINE__." : error, failed to load list of installed apps, call to ".'find_installed_apps()'." has failed with above parameters."); return undef }
		if( 0 == scalar(keys %$apps) ){
			$log->error("${whoami} (via $parent), line ".__LINE__." : error, there are no installed apps, even after enquiring them. The target device has no apps installed. Weird.");
			return undef
		}
	}

	# by now we are sure we have the list of installed apps updated
	# but it is likely that there is no AppProperties object for each
	# app in the list, but we need it, so make a search and if
	# AppProperties is undef, then we need to call find_installed_apps() again.
	my $searchres = $self->search_app({
		'package' => $package,
		'force-reload-apps-list' => 0,
	});
	if( ! defined $searchres ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'search_app()'." has failed for this search term (package) : ${package}"); return undef }
	my $num_searchres = scalar keys %$searchres;
	if( $num_searchres == 0 ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, no app was found for this search term (package) : ${package}"); return undef }
	elsif( $num_searchres > 1 ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, more than one app was found for this search term (package) : ${package} . Apps found: '".join("', '", sort keys %$searchres)."'."); return undef }
	# only 1 tupple in the hash, get it:
	my ($found_app_name, $found_app_properties) = %$searchres;

	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : app to open has been matched to '${found_app_name}'.") }

	if( ! defined $found_app_properties ){
		# the app is there in the list but it does not have AppProperties yet.
		# So get just this one package and non-lazily because we need the AppProperties object:
		my $fpars = {
			'force-reload-apps-list' => 0,
			'lazy' => 1, # << lazy for all other packages except our 'package'
			'packages' => $found_app_name,
		};
		if( ! defined $self->find_installed_apps($fpars) ){ $log->error(perl2dump($fpars)."${whoami} (via $parent), line ".__LINE__." : error, failed to load list of installed apps, call to ".'find_installed_apps()'." has failed with above parameters."); return undef }
		$apps = $self->apps();
		$found_app_properties = $apps->{$found_app_name};
	}

	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : opening app '".$found_app_properties->get('packageName')."' ...") }

	my ($MainActivity, $fact, @cmd);
	if( ! defined($MainActivity=$found_app_properties->get('MainActivity'))
	 || ! exists($MainActivity->{'name-fully-qualified'})
	 || ! defined($fact=$MainActivity->{'name-fully-qualified'})
	){
		$log->warn("${whoami} (via $parent), line ".__LINE__." : error, above app (package '${package}') does not contain a 'MainActivity' entry. Launching without it ...");
		$fact = $found_app_properties->get('packageName');
		@cmd = ('am', 'start', $fact);
	} else {
		@cmd = ('am', 'start', '-n', $fact);
	}

	# open it
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : sending command to adb: @cmd") }
	my $res = $self->adb->shell(@cmd);
	if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return undef }
	if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return undef }

	# we are returning a hash of name=>appproperties
	# but because we allow 1 match only, this hash will only contain 1 item
	# but it will be easier to allow more apps in the future if
	# we return a hash here
	return { $found_app_name => $found_app_properties };
}

# Inputs parameters:
#   'package' => required package name as a SCALAR (for an exact search)
#     or a regex (qr//) object for regex search including case-insensitive.
#     The spec must yield exactly 1 match, it will complain if more than 1 matches found.
#   'force-reload-apps-list' => 0,1 : optionally call find_installed_apps() if > 0
#     but restricted only to the packages match 'package' NOT ALL.
#   'lazy' => 0,1 : pass this lazy value to the find_installed_apps()
#     and be lazy (i.e. without enquiring on each app's specifics
#     and creating an AppProperties object) if ==1
#     or not be lazy if ==0 ...
#     ... (which means an AppProperties object is created for each found package)
#     Default is force-reload-apps-list=>0
#     THIS APPLIES ONLY TO THE MATCHED 'package'
# On success it returns the a hash of {appname => appproperties} of the closed app
#    (which will be created if not existing). It may return {} if no match.
# On failure it returns undef
# it needs that connect_device() to have been called prior to this call
sub close_app {
	my ($self, $params) = @_;
	$params //= {};

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	if( ! $self->is_device_connected() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, you need to connect a device to the desktop and ALSO explicitly call ".'connect_device()'." before calling this."); return undef }

	my ($package);
	if( ! exists($params->{'package'}) || ! defined($package=$params->{'package'}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, input parameter 'package' is required."); return undef }
	if( (ref($package)ne'') && (ref($package)ne'Regexp') ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, the type of input parameter 'package' must be a scalar string (the package name) or a Regexp object (compiled regex via ".'qr//'.")."); return undef }

	# optional activity, else we will see if we find one
	my $activity = (exists($params->{'activity'}) && defined($params->{'activity'})) ? $params->{'activity'} : undef;

	my $force_reload = (exists($params->{'force-reload-apps-list'}) && defined($params->{'force-reload-apps-list'})) ? $params->{'force-reload-apps-list'} : 0;
	my $lazy = (exists($params->{'lazy'}) && defined($params->{'lazy'})) ? $params->{'lazy'} : 1;

	my $apps = $self->apps();
	if( (0 == scalar(keys %$apps))
	 || ($force_reload>0)
	){
		my $fpars = {
			'packages' => $package,
			'force-reload-apps-list' => $force_reload,
			'lazy' => $lazy
		};
		if( ! defined($apps=$self->find_installed_apps($fpars)) ){ $log->error(perl2dump($fpars)."${whoami} (via $parent), line ".__LINE__." : error, failed to load list of installed apps, call to ".'find_installed_apps()'." has failed with above parameters."); return undef }
		if( 0 == scalar(keys %$apps) ){
			$log->error("${whoami} (via $parent), line ".__LINE__." : error, there are no installed apps, even after enquiring them. The target device has no apps installed. Weird.");
			return undef
		}
	}

	# by now we are sure we have the list of installed apps updated
	# but it is likely that there is no AppProperties object for each
	# app in the list, but we need it, so make a search and if
	# AppProperties is undef, then we need to call find_installed_apps() again.
	my $searchres = $self->search_app({
		'package' => $package,
		'force-reload-apps-list' => 0,
	});
	if( ! defined $searchres ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'search_app()'." has failed for this search term (package) : ${package}"); return undef }
	my $num_searchres = scalar keys %$searchres;
	if( $num_searchres == 0 ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, no app was found for this search term (package) : ${package}"); return {} }
	elsif( $num_searchres > 1 ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, more than one app was found for this search term (package) : ${package} . Apps found: '".join("', '", sort keys %$searchres)."'."); return undef }
	# only 1 tupple in the hash, get it:
	my ($found_app_name, $found_app_properties) = %$searchres;

	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : app to open has been matched to '${found_app_name}'.") }

	if( ! defined $found_app_properties ){
		# the app is there in the list but it does not have AppProperties yet.
		# So get just this one package and non-lazily because we need the AppProperties object:
		my $fpars = {
			'force-reload-apps-list' => 0,
			'lazy' => 1, # << lazy for all other packages except our 'package'
			'packages' => $found_app_name,
		};
		if( ! defined $self->find_installed_apps($fpars) ){ $log->error(perl2dump($fpars)."${whoami} (via $parent), line ".__LINE__." : error, failed to load list of installed apps, call to ".'find_installed_apps()'." has failed with above parameters."); return undef }
		$apps = $self->apps();
		$found_app_properties = $apps->{$found_app_name};
	}

	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : closing app '".$found_app_properties->get('packageName')."' ...") }

	# adb shell am force-stop com.my.app
	my @cmd = ('am', 'force-stop', $found_app_properties->get('packageName'));
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : sending command to adb: @cmd") }
	my $res = $self->adb->shell(@cmd);
	if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return undef }
	if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return undef }

	# we are returning a hash of name=>appproperties
	# but because we allow 1 match only, this hash will only contain 1 item
	# but it will be easier to allow more apps in the future if
	# we return a hash here
	return { $found_app_name => $found_app_properties };
}

# returns pid (as a non-negative integer) of the specified app by its exact name
# or -1 if nothing was matched in the process table.
# on error it returns undef
# Note: if you do not know the exact app name e.g. com.viber.voip
# use pgrep()
sub pidof {
	my ($self, $params) = @_;
	$params //= {};

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	if( ! $self->is_device_connected() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, you need to connect a device to the desktop and ALSO explicitly call ".'connect_device()'." before calling this."); return undef }

	if( ! exists($params->{'name'}) || ! defined($params->{'name'}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, missing parameter 'name' is required, it must be the exact app name, if you do not have the exact name then use 'pgrep()'."); return undef }

	my @cmd = ('pidof', $params->{'name'});
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : sending command to adb: @cmd") }
	my $res = $self->adb->shell(@cmd);
	if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return undef }

	# if not found it exits with 1
	if( $res->[0] == 1 ){ return -1 } # nothing matched

	# an error
	if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return undef }

	my $pid = $res->[1];
	if( ! defined $pid ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, because the result got back was undef:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return undef }
	# this is not happening, it exits with 1
	if( $pid =~ /^\s*$/ ){ return -1 } # nothing matched

	# wrong pid format found
	if( $pid !~ /^\s*(\d+)\s*$/m ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, because the result got back was not a pid (as numbers+spaces) but '$pid':\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return undef }
	$pid = $1;
	return $pid; # success, this is the pid
}

# returns an array of pids of the specified app(s) by part of its name,
# There may be more than 1 items in the array if the specified part of its name
# matches many apps.
# on error it returns undef
sub pgrep {
	my ($self, $params) = @_;
	$params //= {};

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	if( ! $self->is_device_connected() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, you need to connect a device to the desktop and ALSO explicitly call ".'connect_device()'." before calling this."); return undef }

	if( ! exists($params->{'name'}) || ! defined($params->{'name'}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, missing parameter 'name' is required, it must be the exact app name, if you do not have the exact name then use 'pgrep()'."); return undef }

	my $dont_show_command_name = (exists($params->{'dont-show-command-name'}) && defined($params->{'dont-show-command-name'}) && ($params->{'dont-show-command-name'}>0)) ? 1 : 0;
	# -f will search the full command name
	# -l will include the command name which is the default
	my @cmdparams = ('-f');
	push(@cmdparams, '-l') unless $dont_show_command_name;

	my @cmd = ('pgrep', @cmdparams, $params->{'name'});
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : sending command to adb: @cmd") }
	my $res = $self->adb->shell(@cmd);
	if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return undef }
	if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return undef }

	# we get something like "954\n995\n1217\n1372\n1392\n1642\n1741\n1856\n1898\n2549\n3236\n4456\n6570\n9245\n10115\n10746\n"

	my $xx = $res->[1];
	if( ! defined $xx ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, because the result got back was undef:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return undef }

	my @results;
	while( $xx =~ /^\s*(\d+)(\s+(.+?))?\s*$/smg ){
		push @results, {
			'pid' => $1,
			'command' => $2 // ''
		};
	}

	return \@results; # success
	# a list of pids, can have 0, 1 or more items
}

# it takes the position on screen to tap either as a
# 'position' => [x,y]
# or
# 'bounds' => [ [topleftX,topleftY], [bottomrightX, bottomrightY] ]
# in which case, the tap position will be the mid-point of the 'bounds'
# rectangle.
# It returns 1 on failure, 0 on success
# it needs that connect_device() to have been called prior to this call
sub tap {
	my ($self, $params) = @_;
	$params //= {};

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	if( ! $self->is_device_connected() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, you need to connect a device to the desktop and ALSO explicitly call ".'connect_device()'." before calling this."); return undef }

	my (@position, $m);
	if( exists($params->{'position'}) && defined($m=$params->{'position'}) ){ 
		@position = ($m->[0], $m->[1]);
	} elsif( exists($params->{'bounds'}) && defined($m=$params->{'bounds'}) ){
		@position = ( int(($m->[1]->[0] + $m->[0]->[0])/2), int(($m->[1]->[1] + $m->[0]->[1])/2) );
	} else { $log->error("${whoami} (via $parent), line ".__LINE__." : error, input parameter 'position' (as ['x','y']) or 'bounds' (as [lefttopX,lefttopY],[bottomrightX,bottomrighY]) was not specified."); return 1 }

	my @cmd = ('input', 'tap', @position);
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : sending command to adb: @cmd") }
	my $res = $self->adb->shell(@cmd);
	if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return 1 }
	if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return 1 }

	return 0; # success
}

# returns 1 on failure, 0 on success
# it needs that connect_device() to have been called prior to this call
sub input_text {
	my ($self, $params) = @_;
	$params //= {};

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	if( ! $self->is_device_connected() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, you need to connect a device to the desktop and ALSO explicitly call ".'connect_device()'." before calling this."); return undef }

	my (@position, $m);
	if( exists($params->{'position'}) && defined($m=$params->{'position'}) ){ 
		@position = ($m->[0], $m->[1]);
	} elsif( exists($params->{'bounds'}) && defined($m=$params->{'bounds'}) ){
		@position = ( int(($m->[1]->[0] + $m->[0]->[0])/2), int(($m->[1]->[1] + $m->[0]->[1])/2) );
	} else { $log->error("${whoami} (via $parent), line ".__LINE__." : error, input parameter 'position' (as ['x','y']) or 'bounds' (as [lefttopX,lefttopY],[bottomrightX,bottomrighY]) was not specified."); return 1 }
	# optional text, else we send just '' (but we clicked on it)
	my $text = (exists($params->{'text'}) && defined($params->{'text'})) ? $params->{'text'} : '';

	# first tap on the text edit widget at the specified coordinates to get focus
	if( $self->tap($params) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to tap on the position of the recipient of the text input"); return 1 }
	usleep(0.8);

	# and send the text
	# adb shell input text 'hello%sworld'
	# does not support unicode and also spaces must be converted to %s
	my @cmd = ('input', 'text', $text);
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : sending command to adb: @cmd") }
	my $res = $self->adb->shell(@cmd);
	if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return 1 }
	if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return 1 }

	return 0; # success
}

# returns 1 on failure, 0 on success
# it needs that connect_device() to have been called prior to this call
sub clear_input_field {
	my ($self, $params) = @_;
	$params //= {};

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	if( ! $self->is_device_connected() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, you need to connect a device to the desktop and ALSO explicitly call ".'connect_device()'." before calling this."); return undef }

	my (@position, $m);
	if( exists($params->{'position'}) && defined($m=$params->{'position'}) ){ 
		@position = ($m->[0], $m->[1]);
	} elsif( exists($params->{'bounds'}) && defined($m=$params->{'bounds'}) ){
		@position = ( int(($m->[1]->[0] + $m->[0]->[0])/2), int(($m->[1]->[1] + $m->[0]->[1])/2) );
	} else { $log->error("${whoami} (via $parent), line ".__LINE__." : error, input parameter 'position' (as ['x','y']) or 'bounds' (as [lefttopX,lefttopY],[bottomrightX,bottomrighY]) was not specified."); return 1 }

	# first tap on the text edit widget at the specified coordinates to get focus
	if( $self->tap($params) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to tap on the position of the recipient of the text input"); return 1 }
	usleep(0.8);

	# from: https://stackoverflow.com/questions/32433303/clear-edit-text-adb
	# the simplest way is input keycombination 113 29 && input keyevent 67
	# but may not work
	# then we try the lame way by erasing all chars one after the other
	# part1:
	my @cmd = ('input', 'keycombination', '113', '29');
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : sending command to adb: @cmd") }
	my $res = $self->adb->shell(@cmd);
	if( ! defined($res) || ($res->[0] != 0) || ($res->[1]=~/Error: Unknown command/) || ($res->[2]=~/Error: Unknown command/) ){
		$log->warn(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed which happens and now will try an alternative ...");
		# alternative/part1
		@cmd = ('input', 'keyevent', 'KEYCODE_MOVE_END');
		if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : sending command to adb: @cmd") }
		$res = $self->adb->shell(@cmd);
		if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening. Info: this is the alternative part1."); return 1 }
		if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed (Info: this is alternative part1), with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return 1 }
		# alternative/part2
		# optional number of chars in the text-edit box, meaning how many
		# times to press backspace, default is here (250)
		# this is only needed for the second method (the failsafe)
		my $numchars = (exists($params->{'num-characters'}) && defined($params->{'num-characters'}) && ($params->{'num-characters'}=~/^\d+$/) ) ? $params->{'num-characters'} : 250;
		@cmd = ('input', 'keyevent', '--longpress', ('KEYCODE_DEL')x$numchars);
		if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : sending command to adb: @cmd") }
		$res = $self->adb->shell(@cmd);
		if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening. Info: this is the alternative part1."); return 1 }
		if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed (Info: this is alternative part1), with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return 1 }
	} else {
		# part2
		# it worked, now on to part 2
		@cmd = ('input', 'keyevent', 'KEYCODE_DEL');
		if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : sending command to adb: @cmd") }
		$res = $self->adb->shell(@cmd);
		if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening. Info: this is the part2."); return 1 }
		if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed (Info: this is part2), with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return 1 }
	}
	return 0; # success
}

# Finds the running processes on device (using a `ps`),
# optionally can save the (parsed) `ps`
# results as JSON to the specified 'filename'.
# It needs that connect_device() to have been called prior to this call
# It returns undef on failure.
# On success, it returns a hash with keys
#   'raw' : the raw output of `ps` as a string
#   'perl': the parsed output of `ps` as a Perl hash of hashes,
#           each process
#           is represented by a hashref of items, e.g. %CPU
#           (basically all the items from the header of the `ps` command)
#           keyed on the full process command and its arguments (verbatim from `ps` output).
#   'json': the above perl data structure converted to JSON.
# NOTE: it uses _ps_parse_output() which is copied verbatim from System::Process
#       I wish they would load ps info from a string rather than running their own `ps`
sub list_running_processes {
	my ($self, $params) = @_;

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $log = $self->log();
	my $verbosity = $self->verbosity;

	if( ! $self->is_device_connected() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, you need to connect a device to the desktop and ALSO explicitly call ".'device_connected()'." before calling this."); return undef }

	my $filename = exists($params->{'filename'}) && defined($params->{'filename'}) ? $params->{'filename'} : undef;
	my $extrafields = exists($params->{'extra-fields'}) && defined($params->{'extra-fields'}) ? $params->{'extra-fields'} : [];

	my ($FH, $tmpfilename) = tempfile(CLEANUP=>$self->cleanup);
	close $FH;

	# WARNING, you need to wake up the phone before dumping !!!!
	my $devicefile = File::Spec->catfile('/', 'data', 'local', 'tmp', $$.'.csv');

	my @cmd = ('ps', '-O', '%CPU', '-O', 'CPU');
	for my $ef (@$extrafields){ push @cmd, '-O', $ef }
	push @cmd, '-f', '-l', '>', $devicefile;

	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : sending command to adb: @cmd") }
	my $res = $self->adb->shell(@cmd);
	if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return undef }
	if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return undef }

	$res = $self->adb->pull($devicefile, $tmpfilename);
	if( ! defined $res ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to pull remote file '$devicefile' into local file '$tmpfilename', because undefined was returned, this should not be happening."); return undef }
	if( $res->[0] != 0 ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to pull remote file '$devicefile' into local file '$tmpfilename' with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return undef }

	@cmd = ("rm", "-f", $devicefile);
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : sending command to adb: @cmd") }
	$res = $self->adb->shell(@cmd);
	if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return undef }
	if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return undef }

	# parse
	if( ! open($FH, '<', $tmpfilename) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to open file with dump for reading '$tmpfilename', $!"); return undef }
	my $contents;
	{ local $/ = undef; $contents = <$FH> } close $FH;
	$contents =~ s/\R+//;
	my @rows = split /\R+/, $contents;
	my @header = split /\s+/, shift @rows;
	my %headerh = map { $_ => 1 } @header;
	my $id = 'PID';
	my $posid = exists($headerh{$id}) ? $headerh{$id} : undef;
	if( ! defined $posid ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to find column name '$id' in above 'ps' output, where is it? what is it called?"); return undef }
	$id = 'CMD';
	my $poscmd = exists($headerh{$id}) ? $headerh{$id} : undef;

	my $n = scalar @header;

	my %psdata;
	while( my $row = shift @rows ){
		$row =~ s/^\s*//;
		my @rowitems = split /\s+/, $row, $n+1;
		my $k = $rowitems[defined($poscmd) ? $poscmd : $posid];
		@{ $psdata{$k} }{@header} = splice @rowitems, 0, $n;
		if( defined $poscmd ){
			$psdata{$k}->{'CMD'} = [ Text::ParseWords::shellwords($psdata{$k}->{'CMD'}) ];
			# now CMD is an arrayref
		}
	}

	my $jsonstr = perl2json(\%psdata);
	if( ! defined $jsonstr ){ $log->error(perl2dump(\%psdata)."${whoami} (via $parent), line ".__LINE__." : error, failed to convert above perl data hash to JSON string."); return undef }
	if( defined $filename ){
		if( ! open($FH, '>:raw', $filename) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to open file '$filename' for writing, $!"); return undef }
		print $FH $jsonstr;
		close $FH;
	}
	return {
		'raw' => $contents,
		'json' => $jsonstr,
		'perl' => \%psdata
	}
}

# ONLY FOR EMULATORS, it fixes the Geolocation to the
# specified coordinates (with 'latitude' and 'longitude').
# returns 1 on failure, 0 on success
# it needs that connect_device() to have been called prior to this call
sub geofix {
	my ($self, $params) = @_;
	$params //= {};

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	if( ! $self->is_device_connected() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, you need to connect a device to the desktop and ALSO explicitly call ".'connect_device()'." before calling this."); return undef }

	for ('latitude', 'longitude'){
		if( ! exists $params->{$_} ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, input parameter '$_' was not specified (as [x,y])."); return 1 }
	}

	my @cmd = ('emu', 'geo', 'fix', $params->{'longitude'}, $params->{'latitude'});
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : sending command to adb: @cmd") }
	my $res = $self->adb->run(@cmd);
	if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return 1 }
	if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return 1 }

	return 0; # success
}

# Get the current GPS location of the device
# according to ALL the GPS providers as a HASH
# keyed on GPS provider name with the information
# the provider provided including lat/lon
# It returns undef undef on failure or the above hash on success.
# NOTE: some providers may exist but have the Location[...] string as null
# meaning not available (e.g. 'network provider' when no internet exists)
# in this case lat,lon etc. will be '<na>' and the strings will be 'null'.
# it needs that connect_device() to have been called prior to this call
sub dump_current_location {
	my ($self, $params) = @_;
	$params //= {};

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	if( ! $self->is_device_connected() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, you need to connect a device to the desktop and ALSO explicitly call ".'connect_device()'." before calling this."); return undef }

	my @cmd = ('dumpsys', 'location');
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : sending command to adb: @cmd") }
	my $res = $self->adb->shell(@cmd);
	if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return 1 }
	if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return 1 }
	my $content = $res->[1];
	# these are the GPS providers in order of preference:
	my $gps;
	for my $prov ('gps provider', 'fused provider', 'passive provider', 'network provider'){
		if( $content =~ /Geofences\:\s+Location Providers\:.*?\n\s+\Q${prov}\E\:\s+last location=(.+?)\R\s+last coarse location=(.+?)\R/sm ){
			my $last_location = $1;
			my $last_coarse_location = $2;
			$gps //= {};
			my ($realprov, $lat, $lon, $las);
			if( $last_location =~ /\s*null\s*$/ ){
				$realprov = '<na>';
				$lat = '<na>';
				$lon = '<na>';
			} else {
				if( $last_location !~ /Location\[(.+?)\s+([-+]?\d+(?:\.\d+)?)\s*[:,]\s*([-+]?\d+(?:\.\d+)?)/ ){ $log->error("--BEGIN content:\n${content}\n--END content\n${whoami} (via $parent), line ".__LINE__." : error, failed to parse last location string: ${last_location}"); return undef }
				$realprov = $1;
				$lat = $2;
				$lon = $3;
			}
			$gps->{$prov} = {
				'provider' => $realprov,
				'latitude' => $lat,
				'longitude' => $lon,
				'last-location-string' => $last_location
			};
			if( ($last_coarse_location !~ /\s*null\s*$/)
			 && ($last_coarse_location !~ /Location\[(.+?)\s+([-+]?\d+(?:\.\d+)?)\s*[:,]\s*([-+]?\d+(?:\.\d+)?)/)
			){ $log->error("--BEGIN content:\n${content}\n--END content\n${whoami} (via $parent), line ".__LINE__." : error, failed to parse last coarse location string: ${last_coarse_location}"); return undef }
			$gps->{$prov}->{'last-coarse-location-string'} = $last_coarse_location;
		}
	}
	if( ! defined $gps ){ $log->error("--BEGIN content:\n${content}\n--END content\n${whoami} (via $parent), line ".__LINE__." : error, location not found in above dumpsys, perhaps it is not enabled?"); return undef }
	return $gps;
}

# It lists the IDs of all the physical displays connected to the
# device, including the main one and returns these back as a HASH
# keyed on display ID.
# it needs that connect_device() to have been called prior to this call
sub list_physical_displays {
	my ($self, $params) = @_;
	$params //= {};

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	if( ! $self->is_device_connected() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, you need to connect a device to the desktop and ALSO explicitly call ".'connect_device()'." before calling this."); return undef }

	my @cmd = ('dumpsys', 'SurfaceFlinger', '--display-id');
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : sending command to adb: @cmd") }
	my $res = $self->adb->shell(@cmd);
	if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return 1 }
	if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return 1 }
	my $content = $res->[1];
	my %ids;
	while( $content =~ /^(Display\s+(.+?)\s+.+?)$/gsm ){
		$ids{$2} = $1
	}
	return \%ids;
}

# It takes a screendump of current screen on device and returns it as
# a Image::PNG object, optionally saving it to the specified file.
# it needs that connect_device() to have been called prior to this call
# It returns undef on failure or the screenshot as an Image::PNG object
# on success.
# it needs that connect_device() to have been called prior to this call
sub dump_current_screen_shot {
	my ($self, $params) = @_;

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $log = $self->log();
	my $verbosity = $self->verbosity;

	if( ! $self->is_device_connected() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, you need to connect a device to the desktop and ALSO explicitly call ".'device_connected()'." before calling this."); return undef }

	my $filename = exists($params->{'filename'}) && defined($params->{'filename'}) ? $params->{'filename'} : undef;

	my $FH;
	if( ! defined $filename ){
		($FH, $filename) = tempfile(CLEANUP=>$self->cleanup);
		close $FH;
	}

	# optional display-id (TODO: confirm that this display id is valid with
	#   dumpsys SurfaceFlinger --display-id
	my @options;
	if( exists($params->{'display-id'}) && defined($params->{'display-id'}) ){
		push @options, '--display-id', $params->{'display-id'}
	}

	# WARNING, you need to wake up the phone before dumping !!!!
	my $devicefile = File::Spec->catfile('/', 'data', 'local', 'tmp', $$.'.png');

	my @cmd = ('screencap', @options, '-p', $devicefile);
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : sending command to adb: @cmd") }
	my $res = $self->adb->shell(@cmd);
	if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return undef }
	if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return undef }

	$res = $self->adb->pull($devicefile, $filename);
	if( ! defined $res ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to pull remote file '$devicefile' into local file '$filename', because undefined was returned, this should not be happening."); return undef }
	if( $res->[0] != 0 ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to pull remote file '$devicefile' into local file '$filename' with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return undef }

	@cmd = ("rm", "-f", $devicefile);
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : sending command to adb: @cmd") }
	$res = $self->adb->shell(@cmd);
	if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return undef }
	if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return undef }

	# let's return the string content back, no we return back an Image::PNG
	#my $contents;
	#if( ! open($FH, '<', $filename) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to open file with dump for reading '$filename', $!"); return undef }
	#{ local $/ = undef; $contents = <$FH> } close $FH;

	# create an Image::PNG to return back
	my $img = Image::PNG->new();
	if( ! defined $img ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'Image::PNG->new()'." has failed."); return undef }
	if( ! $img->read($filename) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to read local file '$filename' as PNG (call to ".'Image::PNG->read()'." has failed)."); return undef }

	return $img;
}

# It takes a video recording of current screen on device and
# saves its to the specified file ($filename).
# Optionally specify 'time-limit' or a default of 10s is used.
# Optionally specify 'bit-rate'.
# Optionally specify %size = ('width' => ..., 'height' => ...)
# Optionally specify if $bugreport==1, then Android will overlay debug info on movie.
# Optionally specify 'display-id'.
# Output format of recording is MP4.
# It returns 1 on failure, 0 on success.
# it needs that connect_device() to have been called prior to this call
sub dump_current_screen_video {
	my ($self, $params) = @_;

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $log = $self->log();
	my $verbosity = $self->verbosity;

	if( ! $self->is_device_connected() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, you need to connect a device to the desktop and ALSO explicitly call ".'device_connected()'." before calling this."); return 1 }

	my $filename = exists($params->{'filename'}) && defined($params->{'filename'}) ? $params->{'filename'} : undef;
	if( ! defined $filename ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, input parameter 'filename' is not specified, an output filename must be specified."); return 1 }

	my @options;
	# optional duration or default of 10 seconds. (Android default is 180 which is stupidly huge for us)
	if( exists($params->{'time-limit'}) && defined($params->{'time-limit'}) ){
		push @options, '--time-limit', $params->{'time-limit'}
	} else { push @options, '--time-limit', '10' }

	# optional bitrate (don't know what Android default is)
	if( exists($params->{'bit-rate'}) && defined($params->{'bit-rate'}) ){
		push @options, '--bit-rate', $params->{'bit-rate'}
	}

	# optional bugreport (Android overlays timestamp etc.)
	if( exists($params->{'bugreport'}) && defined($params->{'bugreport'})
	 && ($params->{'bugreport'} > 0)
	){
		push @options, '--bugreport'
	}

	# optional size
	if( exists($params->{'size'}) && defined($params->{'size'}) ){
		if( (ref($params->{'size'}) ne 'HASH')
		 || (! exists $$params->{'size'}->{'width'})
		 || (! defined $$params->{'size'}->{'width'})
		 || (! exists $$params->{'size'}->{'height'})
		 || (! defined $$params->{'size'}->{'height'}) ){ $log->info("${whoami} (via $parent), line ".__LINE__." : error, specified parameter 'size' is either not a HASHref or it does not contain the two required keys 'width' and 'height'."); return 1 }
		push @options, '--size', $params->{'size'}->{'width'},  $params->{'size'}->{'height'}
	}

	# optional display-id (TODO: confirm that this display id is valid with
	#   dumpsys SurfaceFlinger --display-id
	if( exists($params->{'display-id'}) && defined($params->{'display-id'}) ){
		push @options, '--display-id', $params->{'display-id'}
	}

	# WARNING, you need to wake up the phone before dumping !!!!
	my $devicefile = File::Spec->catfile('/', 'data', 'local', 'tmp', $$.'.mp4');

	my @cmd = ('screenrecord', @options, $devicefile);
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : sending command to adb: @cmd") }
	my $res = $self->adb->shell(@cmd);

	if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return 1 }
	if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return 1 }

	$res = $self->adb->pull($devicefile, $filename);
	if( ! defined $res ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to pull remote file '$devicefile' into local file '$filename', because undefined was returned, this should not be happening."); return 1 }
	if( $res->[0] != 0 ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to pull remote file '$devicefile' into local file '$filename' with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return 1 }

	@cmd = ("rm", "-f", $devicefile);
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : sending command to adb: @cmd") }
	$res = $self->adb->shell(@cmd);
	if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return 1 }
	if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return 1 }

	# let's return the string content back, no we return back 1 or 0, output must be saved to file
	#my $contents;
	#if( ! open($FH, '<', $filename) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to open file with dump for reading '$filename', $!"); return 1 }
	#{ local $/ = undef; $contents = <$FH> } close $FH;

	return 0; # success
}

# returns 1 on failure, 0 on success
# it needs that connect_device() to have been called prior to this call
sub wake_up {
	my ($self, $params) = @_;
	$params //= {};

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	if( ! $self->is_device_connected() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, you need to connect a device to the desktop and ALSO explicitly call ".'connect_device()'." before calling this."); return undef }

	my @cmd = qw/input keyevent KEYCODE_WAKEUP/;
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : sending command to adb: @cmd") }
	my $res = $self->adb->shell(@cmd);
	if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return undef }
	if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return undef }

	return 0; # success
}
# goes to the home screen
# returns 1 on success, 0 on failure
# it needs that connect_device() to have been called prior to this call
sub home_screen {
	my ($self, $params) = @_;
	$params //= {};

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	if( ! $self->is_device_connected() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, you need to connect a device to the desktop and ALSO explicitly call ".'connect_device()'." before calling this."); return undef }

	$self->wake_up();

	my @cmd = qw/am start -a android.intent.action.MAIN -c android.intent.category.HOME/;
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : sending command to adb: @cmd") }
	my $res = $self->adb->shell(@cmd);
	if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return undef }
	if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return undef }

	return 0; # success
}
# It swipes right basically
# it returns 0 on success, 1 on failure
# it needs that connect_device() to have been called prior to this call
sub	next_screen {
	my ($self, $params) = @_;
	$params //= {};

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	if( ! $self->is_device_connected() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, you need to connect a device to the desktop and ALSO explicitly call ".'connect_device()'." before calling this."); return undef }

	if( $self->swipe({'direction' => 'right', dt => 100}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'swipe()'." has failed."); return undef }

	return 0; # success
}

# It swipes left basically
# it returns 0 on success, 1 on failure
# it needs that connect_device() to have been called prior to this call
sub	previous_screen {
	my ($self, $params) = @_;
	$params //= {};

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	if( ! $self->is_device_connected() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, you need to connect a device to the desktop and ALSO explicitly call ".'connect_device()'." before calling this."); return undef }

	if( $self->swipe({'direction' => 'left', dt => 100}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'swipe()'." has failed."); return undef }

	return 0; # success
}

# it returns 0 on success, 1 on failure
# it needs that connect_device() to have been called prior to this call
# the left-triangle button (see http://developer.android.com/reference/android/view/KeyEvent.html)
sub	navigation_menu_back_button {
	my ($self, $params) = @_;
	$params //= {};

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	if( ! $self->is_device_connected() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, you need to connect a device to the desktop and ALSO explicitly call ".'connect_device()'." before calling this."); return undef }

	my @cmd = ('input', 'keyevent', 'KEYCODE_BACK');
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : sending command to adb: @cmd") }
	my $res = $self->adb->shell(@cmd);
	if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return undef }
	if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return undef }

	return 0; # success
}

# it returns 0 on success, 1 on failure
# it needs that connect_device() to have been called prior to this call
# the round button, it goes to home (see http://developer.android.com/reference/android/view/KeyEvent.html)
sub	navigation_menu_home_button {
	my ($self, $params) = @_;
	$params //= {};

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	if( ! $self->is_device_connected() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, you need to connect a device to the desktop and ALSO explicitly call ".'connect_device()'." before calling this."); return undef }

	my @cmd = ('input', 'keyevent', 'KEYCODE_HOME');
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : sending command to adb: @cmd") }
	my $res = $self->adb->shell(@cmd);
	if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return undef }
	if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return undef }

	return 0; # success
}

# it returns 0 on success, 1 on failure
# it needs that connect_device() to have been called prior to this call
# the square button, aka overview, shows all apps running in some sort of gallery view
# (see http://developer.android.com/reference/android/view/KeyEvent.html)
sub	navigation_menu_overview_button {
	my ($self, $params) = @_;
	$params //= {};

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	if( ! $self->is_device_connected() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, you need to connect a device to the desktop and ALSO explicitly call ".'connect_device()'." before calling this."); return undef }

	my @cmd = ('input', 'keyevent', 'KEYCODE_APP_SWITCH');
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : sending command to adb: @cmd") }
	my $res = $self->adb->shell(@cmd);
	if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return undef }
	if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return undef }

	return 0; # success
}

# it swipes up and lists all the apps found in that "drawer"
# with their icon bounds (which is where you "tap").
# It returns undef on failure
# It returns a hashref of all the apps found with their name as key and bounds content etc.
# it needs that connect_device() to have been called prior to this call
sub find_all_apps_roundabout_way {
	my ($self, $params) = @_;
	$params //= {};

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	if( ! $self->is_device_connected() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, you need to connect a device to the desktop and ALSO explicitly call ".'connect_device()'." before calling this."); return undef }

	# go to home, swipe up and all apps will be revealed
	# then dump the UI
	# then swipe down
	if( $self->home_screen() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'home_screen()'." has failed."); return undef }
	usleep(300);

	if( $self->swipe({'direction'=>'up'}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'swipe()'." has failed."); return undef }
	usleep(300);

	my $xmlstr = $self->dump_current_screen_ui();
	if( ! defined $xmlstr ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'dump_current_screen_ui()'." has failed."); return undef }

	if( $self->swipe({'direction'=>'down'}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'swipe()'." has failed."); return undef }

	my $apps = Android::ElectricSheep::Automator::XMLParsers::XMLParser_find_all_apps({
		'xml-string' => $xmlstr
	});
	if( ! defined $apps ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'Android::ElectricSheep::Automator::XMLParsers::XMLParser_find_all_apps()'." has failed."); return undef }

	$self->{'apps-roundabout-way'} = $apps;

	return $apps; # success
}

# It opens the specified (by 'name' or 'bounds' - for tapping) app
# and returns the a hashref with appname (only if name was specified) and bounds
# it needs that connect_device() to have been called prior to this call
sub open_app_roundabout_way {
	my ($self, $params) = @_;
	$params //= {};

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	if( ! $self->is_device_connected() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, you need to connect a device to the desktop and ALSO explicitly call ".'connect_device()'." before calling this."); return undef }

	my $apps = $self->apps_roundabout_way();
	if( (! defined($apps))
	 || (exists($params->{'force-reload-apps-list'}) && defined($params->{'force-reload-apps-list'}) && ($params->{'force-reload-apps-list'}>0))
	){
		if( ! defined $self->find_all_apps_roundabout_way() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to load list of installed apps, call to ".'find_all_apps_roundabout_way()'." has failed."); return undef }
		$apps = $self->apps_roundabout_way();
	}

	my ($position, $appname, $bounds, $name);
	if( exists($params->{'name'}) && defined($name=$params->{'name'}) ){
		my $app;
		# this is an exact match! i don't think a regex match should be allowed,
		# although a case insensitive match would be a good idea
		# so make a new hash of apps, keyed on uppercase names
		if( ! exists($apps->{$name})
		 || ! defined($app=$apps->{$name})
		){
			# case insensitive match
			my $ucname = uc $name;
			my $ucapps = { map { uc $_ => $apps->{$_} } keys %$apps };
			if( ! exists($ucapps->{$ucname})
			 || ! defined($app=$ucapps->{$ucname})
			){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, app with name '".$params->{'name'}."' does not exist either as it is or with a case insensitive search. These are the apps found so far: '".join("', '", sort keys %$apps)."'."); return undef }
		}
		$bounds = $app->{'bounds'};
		$appname = $app->{'name'};
		$position = [ int(($bounds->[0] + $bounds->[2])/2), int(($bounds->[1] + $bounds->[3])/2) ];
	} elsif( exists($params->{'position'}) ){
		$position = $params->{'position'};
	} else {  $log->error("${whoami} (via $parent), line ".__LINE__." : error, one of 'name' or 'position' must be specified in the input parameters, but not both."); return undef }

	# go to home, swipe up and all apps will be revealed
	# click the app (what if it is not visible?)
	# then swipe down
	if( $self->home_screen() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'home_screen()'." has failed."); return undef }
	if( $self->swipe({'direction'=>'up'}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'swipe()'." has failed."); return undef }
	if( $self->tap({'position'=>$position}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'position()'." has failed."); return undef }
	if( $self->swipe({'direction'=>'down'}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'swipe()'." has failed."); return undef }

	return {
		'name' => $appname, # can be undef in only position was specified, TODO: we can find that too
		'bounds' => defined($bounds) ? $bounds : [@$position, 0, 0], # this can leave x2,y2 0
	}; # success
}

sub apps { return $_[0]->{'apps'} }
sub apps_roundabout_way { return $_[0]->{'apps-roundabout-way'} }
sub adb { return $_[0]->{'_private'}->{'Android::ADB'} }
sub log { return $_[0]->{'_private'}->{'log'}->{'logger-object'} }
# returns the current verbosity level optionally setting its value
# Value must be an integer >= 0
# setting a verbosity level will also spawn a chain of other debug subs,
sub verbosity {
	my ($self, $m) = @_;
	my $log = $self->log();
	if( defined $m ){
		my $parent = ( caller(1) )[3] || "N/A";
		my $whoami = ( caller(0) )[3];
		$self->{'_private'}->{'debug'}->{'verbosity'} = $m;
		if( defined $self->adb ){ $self->adb->{'verbosity'} = $m }
	}
	return $self->{'_private'}->{'debug'}->{'verbosity'}
}
sub cleanup {
	my ($self, $m) = @_;
	my $log = $self->log();
	if( defined $m ){
		my $parent = ( caller(1) )[3] || "N/A";
		my $whoami = ( caller(0) )[3];
		$self->{'_private'}->{'debug'}->{'cleanup'} = $m;
	}
	return $self->{'_private'}->{'debug'}->{'cleanup'}
}

# return configfile or read+check+set a configfile,
# returns undef on failure or the configfile on success
sub configfile {
	my ($self, $infile) = @_;

	return $self->{'_private'}->{'configfile'} unless defined $infile;

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	# this can be called before the logger is created, so create a temp logger for this
	my $log = $self->log() // Mojo::Log->new();

	my $ch = parse_configfile($infile, $log);
	if( ! defined $ch ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'parse_configfile()'." has failed for configuration file '$infile'."); return undef }

	# set it in self, it will also do checks on required keys
	if( ! defined $self->confighash($ch) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to load specified confighash, , there must be errors in the configuration."); return undef }

	$self->{'_private'}->{'configfile'} = $infile;

	return $infile #success
}

# return configfile or read+check+set a configfile,
# returns undef on failure or the configfile on success
sub parse_configfile {
	my ($infile, $log) = @_;

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	# this can be called before the logger is created, so create a temp logger for this
	$log //= Mojo::Log->new();

	my $ch = Config::JSON::Enhanced::config2perl({
		'filename' => $infile,
		'commentstyle' => 'custom(</*)(*/>)',
		'tags' => ['<%','%>'],
		'variable-substitutions' => {
			'SCRIPTDIR' => Cwd::abs_path($FindBin::Bin),
		},
	});

	if( ! defined $ch ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'Config::JSON::Enhanced::config2perl()'." has failed for configuration file '$infile'."); return undef }

	return $ch; #success
}

# returns the confighash stored or if one is supplied
# it checks it and sets it and returns it
# or it returns undef on failure
# NOTE, if param is specified then we assume we do not have any configuration,
#       we do not have a logger yet, we have no configuration, no verbosity, etc.
sub confighash {
	my ($self, $m) = @_;

	if( ! defined $m ){ return $self->{'_private'}->{'confighash'} }

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	#print STDOUT "${whoami} (via $parent), line ".__LINE__." : called ...\n";

	# we are storing specified confighash but first check it for some fields
	# required fields:
	for ('adb', 'debug', 'logger'){
		if( ! exists($m->{$_}) || ! defined($m->{$_}) ){ print STDERR "${whoami} (via $parent), line ".__LINE__." : error, configuration does not have key '$_'.\n"; return undef }
	}

	my $x;
	# adb params
	$x = $m->{'adb'};
	for ('path-to-executable'){
		if( ! exists($x->{$_}) || ! defined($x->{$_}) ){ print STDERR "${whoami} (via $parent), line ".__LINE__." : error, configuration does not have key '$_'.\n"; return undef }
	}

	# debug params
	$x = $m->{'debug'};
	if( exists($x->{'verbosity'}) && defined($x->{'verbosity'}) ){
		$self->verbosity($x->{'verbosity'});
	}
	if( exists($x->{'cleanup'}) && defined($x->{'cleanup'}) ){
		$self->cleanup($x->{'cleanup'});
	}

	# create logger if specified but only if one does not exist
	$x = $m->{'logger'};
	if( exists($x->{'filename'}) && defined($x->{'filename'})
	 && (! defined($self->log()))
	){
		$self->log(Mojo::Log->new(path => $x->{'filename'}));
	}

	# ok!
	$self->{'_private'}->{'confighash'} = $m;
	return $m
}

# initialises
# do the verbositys
# returns 1 on failure, 0 on success
sub init {
	my ($self, $params) = @_;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	# Confighash
	# first see if either user specified a config file or the default is present and read it,
	# then we will overwrite with user-specified params if any
	my ($configfile, $confighash);
	if( exists($params->{'configfile'}) && defined($configfile=$params->{'configfile'}) ){
		if( ! -f $configfile ){ print STDERR __PACKAGE__."${whoami} (via $parent), line ".__LINE__." : error, specified configfile '$configfile' does not exist or it is not a file.\n"; return 1 }
		# this reads, creates confighash and calls confighash() which will do all the tests
		if( ! defined $self->configfile($configfile) ){ print STDERR __PACKAGE__."${whoami} (via $parent), line ".__LINE__." : error, call to ".'configfile()'." has failed for configfile '$configfile'.\n"; return 1 }
		$confighash = $self->confighash();
	} elsif( exists($params->{'confighash'}) && defined($params->{'confighash'}) ){
		$confighash = $params->{'confighash'};
		# this sets the confighash and checks it too
		if( ! defined $self->confighash($confighash) ){ print STDERR __PACKAGE__."${whoami} (via $parent), line ".__LINE__." : error, call to ".'confighash()'." has failed.\n"; return 1 }
	} else {
		# use default config
		$confighash = Config::JSON::Enhanced::config2perl({
			'string' => $_DEFAULT_CONFIG,
			'commentstyle' => 'custom(</*)(*/>)',
			'tags' => ['<%','%>'],
			'variable-substitutions' => {
				'SCRIPTDIR' => Cwd::abs_path($FindBin::Bin),
			},
		});
		if( ! defined $confighash ){ print STDERR $_DEFAULT_CONFIG."\n\n".__PACKAGE__."${whoami} (via $parent), line ".__LINE__." : error, failed to parse default configuration string, above.\n"; return undef }
		if( ! defined $self->confighash($confighash) ){ print STDERR __PACKAGE__."${whoami} (via $parent), line ".__LINE__." : error, call to ".'confighash()'." has failed.\n"; return 1 }
	}
	# by now we have a confighash in self or died

	# for creating the logger: check
	#  1. params if they have logger or logfile
	#  2. our own confighash if it contains logfile
	#  3. if all else fails, create a vanilla logger
	if( exists($params->{'logger'}) && defined($params->{'logger'}) ){
		$self->{'_private'}->{'log'}->{'logger-object'} = $params->{'logger'};
		#print STDOUT "${whoami} (via $parent), line ".__LINE__." : using user-supplied logger object.\n";
	} elsif( exists($params->{'logfile'}) && defined($params->{'logfile'}) ){
		$self->{'_private'}->{'log'}->{'logger-object'} = Mojo::Log->new(path => $params->{'logfile'});
		#print STDOUT "${whoami} (via $parent), line ".__LINE__." : logging to file '".$params->{'logfile'}."'.\n";
	} elsif( ! defined($self->{'_private'}->{'log'}->{'logger-object'}) ){
		$self->{'_private'}->{'log'}->{'logger-object'} = Mojo::Log->new();
		#print STDOUT "${whoami} (via $parent), line ".__LINE__." : a vanilla logger has been created to log to the console.\n";
	}

        # Now we have a logger
        my $log = $self->log();
        $log->short(1);

	# Set verbosity and cleanup as follows:
	#  1. check if exists in params
	#  2. check if exists in confighash
	#  3. set default value
	my $v;
	if( exists($params->{'verbosity'}) && defined($params->{'verbosity'}) ){
		$v = $params->{'verbosity'};
	} elsif( exists($confighash->{'debug'}) && exists($confighash->{'debug'}->{'verbosity'}) && defined($confighash->{'debug'}->{'verbosity'}) ){
		$v = $confighash->{'debug'}->{'verbosity'};
	} else {
		$v = 0; # default
	}
	if( $self->verbosity($v) < 0 ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to 'verbosity()' has failed for value '$v'."); return 1 }

	if( exists($params->{'cleanup'}) && defined($params->{'cleanup'}) ){
		$v = $params->{'cleanup'};
	} elsif( exists($confighash->{'debug'}) && exists($confighash->{'debug'}->{'cleanup'}) && defined($confighash->{'debug'}->{'cleanup'}) ){
		$v = $confighash->{'debug'}->{'cleanup'};
	} else {
		$v = 0; # default
	}
	if( $self->cleanup($v) < 0 ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to 'cleanup()' has failed for value '$v'."); return 1 }

	return 0 # success
}

# initialises module-specific things, no need to copy this to other modules
# returns 1 on failure, 0 on success
sub init_module_specific {
	my ($self, $params) = @_;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();
	my $confighash = $self->confighash();
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : called ...") }

	# set or create the Android::ADB object
	if( exists($params->{'adb'}) && defined($params->{'adb'}) ){
		# caller supplied an existing ADB object
		$self->{'_private'}->{'Android::ADB'} = $params->{'adb'}
	} else {
		# no, we need to instantiate one, we need params in confighash
		my $pathtoadb = (exists($params->{'adb-path-to-executable'}) && defined($params->{'adb-path-to-executable'}))
			? $params->{'adb-path-to-executable'}
			: $self->confighash->{'adb'}->{'path-to-executable'}
		;
		if( ! -x $pathtoadb ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, specified adb executable '${pathtoadb}' is not an executable or does not exist."); return 1; }
		if( ! defined ($self->{'_private'}->{'Android::ADB'}=Android::ElectricSheep::Automator::ADB->new(
			path => $pathtoadb,
			verbosity => $self->verbosity
		)) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'Android::ElectricSheep::Automator::ADB->new()'." has failed (path to executable was specified as '$pathtoadb')."); return 1; }
	}

	# does caller have a device connected to the desktop and wants us to
	# target it?
	# if just one device, we don't need serial etc:
	my $device_params;
	if( exists($params->{'device-is-connected'}) && defined($params->{'device-is-connected'}) && ($params->{'device-is-connected'}>0) ){
		# just one device, we don't need serial of the device
		$device_params = {};
	} elsif( exists($params->{'device-serial'}) && defined($params->{'device-serial'}) ){
		$device_params = {'serial' => $params->{'device-serial'}};
	} elsif( exists($params->{'device-object'}) && defined($params->{'device-object'}) ){
		$device_params = {'device-object' => $params->{'device-object'}};
	}
	if( defined $device_params ){
		my $devobj = $self->connect_device($device_params);
		if( ! defined $devobj ){ $log->error(perl2dump($device_params)."${whoami} (via $parent), line ".__LINE__." : error, failed to connect to device with above parameters (call to ".'connect_device()'." has failed."); return undef }
		if( $verbosity > 0 ){ $log->info($devobj."\n${whoami} (via $parent), line ".__LINE__." : device set as above.") }
	}

	# done
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : ".__PACKAGE__." has been initialised ...") }
	return 0 # success
}

sub disconnect_device {
	my ($self, $params) = @_;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : called ...") }

	$self->{'device-properties'} = undef;
	$self->{'device-object'} = undef;

	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : done.") }
	return 0; # success
}
# prefer to return 1 0 than '', 1
sub is_device_connected { return defined($_[0]->{'device-properties'}) ? 1 : 0 }

# enquire screen properties (e.g. w, h) and save them to our $self
# if already exists a DeviceProperties object, then we just return that
# and do nothing UNLESS param 'force' => 1
# On failure it returns undef
# On success it creates a new DeviceProperties Object which is saved in $self
# and also returned to caller
sub find_current_device_properties {
	my ($self, $params) = @_;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();
	my $confighash = $self->confighash();
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : called ...") }

	my $sl;
	if( defined($sl=$self->device_properties())
	 || (
		   exists($params->{'force'})
		&& defined($params->{'force'})
		&& ($params->{'force'}==0)
	    )
	){
		# there is no need to re-enquire, we have them already
		# and no 'force' was specified
		return $sl
	}

	$sl = Android::ElectricSheep::Automator::DeviceProperties->new({'mother'=>$self});
	if( ! defined $sl ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'Android::ElectricSheep::Automator::DeviceProperties->new()'." has failed."); return undef }
	if( $sl->enquire() ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'Android::ElectricSheep::Automator::DeviceProperties->enquire()'." has failed."); return undef }

	$self->{'device-properties'} = $sl;

	return $sl;
}

# only pod below
=pod

=encoding utf8

=head1 NAME

Android::ElectricSheep::Automator - Do Androids Dream of Electric Sheep? Smartphone control from your desktop.

=head1 VERSION

Version 0.05

=head1 WARNING

Current distribution is extremely alpha. API may change. 

=head1 SYNOPSIS

The present package fascilitates the control
of a USB-debugging-enabled
Android device, e.g. a real smartphone,
or an emulated (virtual) Android device,
from your desktop computer using Perl.
It's basically a thickishly-thin wrapper
to the omnipotent Android Debug Bridge (adb)
program.

B<Note that absolutely nothing is
installed on the connected device,
neither any of its settings will be modified by this package>.
See L</WILL ANYTHING BE INSTALLED ON THE DEVICE?>.

    use Android::ElectricSheep::Automator;

    my $mother = Android::ElectricSheep::Automator->new({
      # optional as there is a default, but you may have
      # problems with the location of the adb executable
      'configfile' => $configfile,
      'verbosity' => 1,
      # we already have a device connected and ready to control
      'device-is-connected' => 1,
    });

    # find the devices connected to desktop and set one.
    my @devices = $mother->adb->devices;
    $mother->connect_device({'serial' => $devices->[0]->serial})
	or die;
    # no device needs to be specified if just one:
    $mother->connect_device() if scalar(@devices)==0;

    # Go Home
    $mother->home_screen() or die;

    # swipe up/down/left/right
    $mother->swipe({'direction'=>up}) or die;
    # dt is the time to swipe in millis,
    # the shorter the faster the swipe
    $mother->swipe({'direction'=>left, 'dt'=>100}) or die;

    # tap
    $mother->tap({'position'=>[100,200]});

    # uses swipe() to move in screens (horizontally):
    $mother->next_screen() or die;
    $mother->previous_screen() or die;

    # bottom navigation:
    # the "triangle" back button
    $mother->navigation_menu_back_button() or die;
    # the "circle" home button
    $mother->navigation_menu_home_button() or die;
    # the "square" overview button
    $mother->navigation_menu_overview_button() or die;

    # open/close apps
    $mother->open_app({'package'=>qr/calendar$/i}) or die;
    $mother->close_app({'package'=>qr/calendar$/i}) or die;

    # push pull files
    $mother->adb->pull($deviceFile, $localFile);
    $mother->adb->push($localFile, $deviceFileOrDir);

    # guess what!
    my $xmlstr = $mother->dump_current_screen_ui();

=head1 CONSTRUCTOR

=head2 new($params)

Creates a new C<Android::ElectricSheep::Automator> object. C<$params>
is a hash reference used to pass initialization options which may
or should include the following:

=over 4

=item B<C<confighash>> or B<C<configfile>>

the configuration
file holds
configuration parameters and its format is "enhanced" JSON
(see L<use Config::JSON::Enhanced>) which is basically JSON
which allows comments between C< E<lt>/* > and C< */E<gt> >.

Here is an example configuration file to get you started:

  {
    "adb" : {
        "path-to-executable" : "/usr/local/android-sdk/platform-tools/adb"
    },
    "debug" : {
        "verbosity" : 0,
        </* cleanup temp files on exit */>
        "cleanup" : 1
    },
    "logger" : {
        </* log to file if you uncomment this, else console */>
        "filename" : "my.log"
    }
  }

All sections in the configuration are mandatory.
Setting C<"adb"> to the wrong path will yield problems.

C<confighash> is a hash of configuration options with
structure as above and can be supplied to the constructor
instead of the configuration file.

If no configuration is specified, then a default
configuration will be used. In this case please
specify B<C<adb-path-to-executable>> to point
to the location of C<adb>. Most likely
the default path will not work for you.

=item B<C<adb-path-to-executable>>

optionally specify the path to the C<adb> executable in
your desktop system. This will override the setting
C< 'adb'-E<gt>'path-to-executable' > in the configuration,
if it was provided. Use this option if you are not
providing any configuration and so the default configuration
will be used. But it will most likely fail because of this
path not being correct for your system. So, if you are going
to omit providing a configuration and the default configuration
will be used do specify the C<adb> path via this option (but you
don't have to and your mileage may vary).

=item B<C<device-serial>> or B<C<device-object>>

optionally specify the serial
of a device to connect to on instantiation,
or a L<Android::ElectricSheep::Automator::DeviceProperties>
object you already have handy. Alternatively,
use L</connect_device($params)> to set the connected device at a later
time. Note that there is no need to specify a
device if there is exactly one connected device.

=item B<C<adb>>

optionally specify an already created L<Android::ADB> object.
Otherwise, a fresh object will be created based
on the configuration under the C<adb> section of the configuration.

=item B<C<device-is-connected>>

optionally set it to 1
in order to communicate with the device
and get some information about it like
screen size, resolution, orientation, etc.
And also allow use of
functionality which needs communicating with a device
like L</swipe($params)>, L</home_screen($params)>,
L</open_app($params)>, etc.
After instantiation, you can use the
method L</connect_device($params)> and
L</disconnect_device()> for conveying
this information to the module.
Also note that if there are
more than one devices connected to the desktop, make sure
you specify which one with the C<device> parameter.
Default value is 0.

=item B<C<logger>>

optionally specify a logger object
to be used (instead of creating a fresh one). This object
must implement C<info()>, C<warn()>, C<error()>. For
example L<Mojo::Log>.

=item B<C<logfile>>

optionally specify a file to
save logging output to. This overrides the C<filename>
key under section C<logger> of the configuration.

=item B<C<verbosity>>

optionally specify a verbosity level
which will override what the configuration contains. Default
is C<0>.

=item B<C<cleanup>>

optionally specify a flag to clean up
any temp files after exit which will override what the
configuration contains. Default is C<1>, meaning Yes!.

=back

=head1 METHODS

Note:

=over 4

=item B<C<ARRAY_REF>> : C<my $ar = [1,2,3]; my $ar = \@ahash; my @anarray = @$ar;>

=item B<C<HASH_REF>> : C<my $hr = {1=>1, 2=>2}; my $hr = \%ahash; my %ahash = %$hr;>

=item In this module parameters to functions are passed as a HASH_REF.
Functions return back objects, ARRAY_REF or HASH_REF.

=back

=over 1

=item devices()

Lists all Android devices connected to your
desktop and returns these as an ARRAY_REF which can be empty.

It returns C<undef> on failure.

=item connect_device($params)

Specifies the current Android device to control. Its use is
required only if you have more than one devices connected.
C<$params> is a HASH_REF which should contain exactly
one of the following:

=over 4

=item B<C<serial>> should contain
the serial (string) of the connected device as returned
by L</devices()>.

=item B<C<device-object>> should be
an already existing L<Android::ElectricSheep::Automator::DeviceProperties>
object.

=back

It returns C<0> on success, C<1> on failure.

=item dump_current_screen_ui($params)

It dumps the current screen as XML and returns that as
a string, optionally saving it to the specified file.

C<$params> is a HASH_REF which may or should contain:

=over 4

=item B<C<filename>>

optionally save the returned XML string to the specified file.

=back

It returns C<undef> on failure or the UI XML dump, as a string, on success.

=item dump_current_screen_shot($params)

It dumps the current screen as a PNG image and returns that as
a L<Image::PNG> object, optionally saving it to the specified file.

C<$params> is a HASH_REF which may or should contain:

=over 4

=item B<C<filename>>

optionally save the returned XML string to the specified file.

=back

It returns C<undef> on failure or a L<Image::PNG> image, on success.

=item dump_current_screen_video($params)

It dumps the current screen as MP4 video and saves that
in specified file.

C<$params> is a HASH_REF which may or should contain:

=over 4

=item B<C<filename>>

save the recorded video to the specified file in MP4 format. This
is required.

=item B<C<time-limit>>

optionally specify the duration of the recorded video, in seconds. Default is 10 seconds.

=item B<C<bit-rate>>

optionally specify the bit rate of the recorded video in bits per second. Default is 20Mbps.

# Optionally specify %size = ('width' => ..., 'height' => ...)

=item B<C<size>>

optionally specify the size (geometry) of the recorded video as a
HASH_REF with keys C<width> and C<height>, in pixels. Default is "I<the
device's main display resolution>".

=item B<C<bugreport>>

optionally set this flag to 1 to have Android overlay debug information
on the recorded video, e.g. timestamp.

# Optionally specify 'display-id'.
=item B<C<display-id>>

for a device set up with multiple physical displays, optionally
specify which one to record -- if not the main display -- by providing the
display id. You can find display ids with L</list_physical_displays()>
or, from the CLI, by C<adb shell dumpsys SurfaceFlinger --display-id>

=back

C<adb shell screenrecord --help> contains some more documentation.

=item list_running_processes($params)

It finds the running processes on device (using a `ps`),
optionally can save the (parsed) `ps`
results as JSON to the specified 'filename'.
It returns C<undef> on failure or the results as a hash of hashes on success.

C<$params> is a HASH_REF which may or should contain:

=over 4

=item B<C<extra-fields>>

optionally add more fields (columns) to the report by C<ps>, as an ARRAY_REF.
For example, C<['TTY','TIME']>.

=back

It needs that connect_device() to have been called prior to this call

It returns C<undef> on failure or a hash with these keys on success:

=over 4

=item B<C<raw>> : contains the raw `ps` output as a string.

=item B<C<perl>> : contains the parsed raw output as a Perl hash with
each item corresponding to one process, keyed on process command and arguments
(as reported by `ps`, verbatim), as a hash keyed on each field (column)
of the `ps` output.

=item B<C<json>> : the above data converted into a JSON string.

=back

=item pidof($params)

It returns the PID of the specified command name.
The specified command name must match the app or command
name exactly. B<Use C<pgrep()> if you want to match command
names with a regular expression>.

C<$params> is a HASH_REF which should contain:

=over 4

=item B<C<name>>

the name of the process. It can be a command name,
e.g. C<audioserver> or an app name e.g. C<android.hardware.vibrator-service.example>.

=back

It returns C<undef> on failure or the PID of the matched command on success.

=back

=item pgrep($params)

It returns the PIDs matching the specified command or app
name (which can be an extended regular expression that C<pgrep>
understands). The returned array will contain zero, one or more
hashes with keys C<pid> and C<command>. The former key is the pid of the command
whose full name (as per the process table) will be under the latter key.
Unless parameter C<dont-show-command-name> was set to C<1>.

C<$params> is a HASH_REF which should contain:

=over 4

=item B<C<name>>

the name of the process. It can be a command name,
e.g. C<audioserver> or an app name e.g. C<android.hardware.vibrator-service.example>
or part of these e.g. C<audio> or C<hardware> or an extended
regular expression that Android's C<pgrep> understands, e.g.
C<^com.+google.+mess>.

=back

It returns C<undef> on failure or an ARRAY_REF containing
a HASH_REF of data for each command matched (under keys C<pid> and C<command>).
The returned ARRAY_REF can contain 0, 1 or more items depending
on what was matched.

=back

=item geofix($params)

It fixes the geolocation of the device to the specified coordinates.
After this, app API calls to get current geolocation will result to this
position (unless they use their own, roundabout way).

C<$params> is a HASH_REF which should contain:

=over 4

=item B<C<latitude>>

the latitude of the position as a floating point number.

=item B<C<longitude>>

the longitude of the position as a floating point number.

=back

It returns C<1> on failure or a C<0> on success.

=item dump_current_location()

It finds the current GPS location of the device
according to ALL the GPS providers available.

It needs that connect_device() to have been called prior to this call

It takes no parameters.

On failure, it returns C<undef>.

On success, it returns a HASH_REF of results.
Each item will be keyed on provider name (e.g. 'C<network provider>')
and will contain the parsed output of
what each GPS provider returned as a HASH_REF with
the following keys:

=over 4

=item B<C<provider>> : the provider name. This is also the key of the item
in the parent hash.

=item B<C<latitude>> : the latitude as a floating point number (can be negative too)
or C< E<lt>naE<gt> > if the provider failed to return valid output.

=item B<C<longitude>> : the longitude as a floating point number (can be negative too)
or C< E<lt>na E<gt> > if the provider failed to return valid output.

=item B<C<last-location-string>> : the last location string, or
C< E<lt>na E<gt> > if the provider failed to return valid output.

=back

=item is_app_running($params)

It checks if the specified app is running on the device.
The name of the app must be exact.
Note that you can search for running apps / commands
with extended regular expressions using C<pgrep()>

C<$params> is a HASH_REF which should contain:

=over 4

=item B<C<appname>>

the name of the app to check if it is running.
It must be its exact name. Basically it checks the
output of C<pidof()>.

=back

It returns C<undef> on failure,
C<1> if the app is running or C<0> if the app is not running.

=back

=item find_current_device_properties($params)

It enquires the device currently connected,
and specified with L</connect_device($params)>, if needed,
and returns back an L<Android::ElectricSheep::Automator::DeviceProperties>
object containing this information, for example screen size,
resolution, serial number, etc.

It returns L<Android::ElectricSheep::Automator::DeviceProperties>
object on success or C<undef> on failure.

=item connect_device()

It signals to our object that there is now
a device connected to the desktop and its
enquiry and subsequent control can commence.
If this is not called and neither C<device-is-connected =E<gt> 1>
is specified as a parameter to the constructor, then
the functionality will be limited and access
to functions like C<swipe()>, C<open_app()>, etc.
will be blocked until the caller signals that
a device is now connected to the desktop.

Using L</connect_device($params)> to specify which device
to target in the case of multiple devices
connected to the desktop will also call this
method.

This method will try to enquire the connected device
about some of its properties, like screen size,
resolution, orientation, serial number etc.
This information will subsequently be available
via C<$self-E<gt>>device_properties()>.

It returns C<0> on success, C<1> on failure.

=item disconnect_device()

Signals to our object that it should consider
that there is currently no device connected to
the desktop (irrespective of that is true or not)
which will block access to L</swipe()>, L</open_app()>, etc.

=item device_properties()

It returns the currently connected device properties
as a L<Android::ElectricSheep::Automator::DeviceProperties>
object or C<undef> if there is no connected device.
The returned object is constructed during a call
to L</find_current_device_properties()>
which is called via L</connect_device($params)> and will persist
for the duration of the connection.
However, after a call to L</disconnect_device()>
this object will be discarded and C<undef> will be
returned.

=item swipe($params)

Emulates a "swipe" in four directions.
Sets the current Android device to control. It is only
required if you have more than one device connected.
C<$params> is a HASH_REF which may or should contain:

=over 4

=item B<C<direction>>

should be one of

=over 4

=item up

=item down

=item left

=item right

=back

=item B<C<dt>>

denotes the time taken for the swipe
in milliseconds. The smaller its value the faster
the swipe. A value of C<100> is fast enough to swipe to
the next screen.

=back

It returns C<0> on success, C<1> on failure.

=item tap($params)

Emulates a "tap" at the specified location.
C<$params> is a HASH_REF which must contain one
of the following items:

=over 4

=item B<C<position>>

should be an ARRAY_REF
as the C<X,Y> coordinates of the point to "tap".

=item B<C<bounds>>

should be an ARRAY_REF of a bounding rectangle
of the widget to tap. Which contains two ARRAY_REFs
for the top-left and bottom-right coordinates, e.g.
C< [ [tlX,tlY], [brX,brY] ] >. This is convenient
when the widget is extracted from an XML dump of
the UI (see L</dump_current_screen_ui()>) which
contains exactly this bounding rectangle.

=back

It returns C<0> on success, C<1> on failure.

=item input_text($params)

It inputs the specified text into a text-input widget
at specified position. At first it taps at the widget's
location in order to get the focus. And then it enters
the text.

C<$params> is a HASH_REF which must contain C<text>
and one of the two position (of the text-edit widget)
specifiers C<position> or C<bounds>:

=over 4

=item B<C<text>>

the text to write on the text edit widget. At the
moment, this must be plain ASCII string, not unicode.
No spaces are accepted.
Each space character must be replaced with C<%s>.

=item B<C<position>>

should be an ARRAY_REF
as the C<X,Y> coordinates of the point to "tap" in order
to get the focus of the text edit widget, preceding the
text input.

=item B<C<bounds>>

should be an ARRAY_REF of a bounding rectangle
of the widget to tap, in order to get the focus, preceding
the text input. Which contains two ARRAY_REFs
for the top-left and bottom-right coordinates, e.g.
C< [ [tlX,tlY], [brX,brY] ] >. This is convenient
when the widget is extracted from an XML dump of
the UI (see L</dump_current_screen_ui()>) which
contains exactly this bounding rectangle.

=back

It returns C<0> on success, C<1> on failure.

=item clear_input_field($params)

It clears the contents of a text-input widget
at specified location.

There are several ways to do this. The simplest way
(with C<keycombination>) does not work in some
devices, in which case a failsafe way is employed
which deletes characters one after the other for
250 times. 

C<$params> is a HASH_REF which must contain
one of the two position (of the text-edit widget)
specifiers C<position> or C<bounds>:

=over 4

=item B<C<position>>

should be an ARRAY_REF
as the C<X,Y> coordinates of the point to "tap" in order
to get the focus of the text edit widget, preceding the
text input.

=item B<C<bounds>>

should be an ARRAY_REF of a bounding rectangle
of the widget to tap, in order to get the focus, preceding
the text input. Which contains two ARRAY_REFs
for the top-left and bottom-right coordinates, e.g.
C< [ [tlX,tlY], [brX,brY] ] >. This is convenient
when the widget is extracted from an XML dump of
the UI (see L</dump_current_screen_ui()>) which
contains exactly this bounding rectangle.

=item B<C<num-characters>>

how many times to press the backspace? Default is 250!
But if you know the length of the text currently at
the text-edit widget then enter this here.

=back

It returns C<0> on success, C<1> on failure.

=item home_screen()

Go to the "home" screen.

It returns C<0> on success, C<1> on failure.


=item wake_up()

"Wake" up the device.

It returns C<0> on success, C<1> on failure.


=item next_screen()

Swipe to the next screen (on the right).

It returns C<0> on success, C<1> on failure.


=item previous_screen()

Swipe to the previous screen (on the left).

It returns C<0> on success, C<1> on failure.


=item navigation_menu_back_button()

Press the "back" button which is the triangular
button at the left of the navigation menu at the bottom.

It returns C<0> on success, C<1> on failure.

=item navigation_menu_home_button()

Press the "home" button which is the circular
button in the middle of the navigation menu at the bottom.

It returns C<0> on success, C<1> on failure.

=item navigation_menu_overview_button()

Press the "overview" button which is the square
button at the right of the navigation menu at the bottom.

It returns C<0> on success, C<1> on failure.

=item apps()

It returns a HASH_REF containing all the
packages (apps) installed on the device
keyed on package name (which is like C<com.android.settings>.
The list of installed apps is populated either
if C<device-is-connected> is set to 1 during construction
or a call has been made to any of these
methods: C<open_app()>, C<close_app()>,
C<search_app()>, C<find_installed_apps()>.

=item find_installed_apps($params)

It enquires the device about all the installed
packages (apps) it has for the purpose of
opening and closing apps with C<open_app()> and C<close_app()>.
This list is available using C<$self->apps>.

Finding the package names is done in a single
operation and does
not take long. But enquiring with the connected device
about the main activity/ies
of each package takes some time as there should be
one enquiry for each package. By default,
C<find_installed_apps()> will find all the package names
but will not enquire each package (fast).
This enquiry will be
done lazily if and when you need to open or close that
app.

C<$params> is a HASH_REF which may or should contain:

=over 4

=item B<C<packages>>

is a list of package names to enquire
about with the device. It can be a scalar string with the
exact package name, e.g. C<com.android.settings>, or
a L<Regexp> object which is a compiled regular expression
created by e.g. C<qr/^\.com.+?\.settings$/i>, or
an ARRAY_REF of package names. Or a HASH_REF where
keys are package names. For each of the packages matched
witht this specification a full enquiry will be made
with the connected device. The information will
be saved in a L<Android::ElectricSheep::Automator::AppProperties>
object and will include the main activity/ies, permissions requested etc.

=item B<C<lazy>>

is a flag to denote whether to enquire
information about each package (app) at the time of this
call (set it to C<1>) or lazily, on a if-and-when-needed basis
(set it to C<0> which is the default). C<lazy> affects
all packages except those specified in C<packages>, if any.
Default is C<1>.

=item B<C<force-reload-apps-list'>>

can be set to 1 to
erase previous packages information and start fresh.
Default is C<0>.

=back

It returns a HASH_REF of packages names (keys) along
with enquired information (as a L<Android::ElectricSheep::Automator::AppProperties>
object) or C<undef> if this information was not
obtained (e.g. when C<lazy> is set to 1).
It also sets the exact same data to be available
via C<$self->apps>.

=item search_app($params)

It searches the list of installed packages (apps)
on the current device and returns the match(es)
as a HASH_REF keyed on package name which may
have as values L<Android::ElectricSheep::Automator::AppProperties>
objects with packages information. If there are
no entries yet in the list of installed packages,
it calls the C<find_installed_apps()> first to populate it.

C<$params> is a HASH_REF which may or should contain:

=over 4

=item B<C<package>>

is required. It can either be
a scalar string with the exact package name
or a L<Regexp> object which is a compiled regular expression
created by e.g. C<qr/^\.com.+?\.settings$/i>.

=item B<C<lazy>>

is a flag to be passed on to L</find_installed_apps()>,
if needed, to denote whether to enquire
information about each package (app) at the time of this
call (set it to C<1>) or lazily, on a if-and-when-needed basis
(set it to C<0> which is the default). C<lazy> affects
all packages except those specified in C<packages>, if any. Default is C<1>.

=item B<C<force-reload-apps-list'>>

is a flag to be passed on to L</find_installed_apps()>,
if needed, and can be set to 1 to
erase previous packages information and start fresh. Default is C<0>.

=back

It returns a HASH_REF of matched packages names (keys) along
with enquired information (as a L<Android::ElectricSheep::Automator::AppProperties>
object) or C<undef> if this information was not
obtained (e.g. when C<lazy> is set to 1).

=item open_app($params)

It opens the package specified in C<$params>
on the current device. If there are
no entries yet in the list of installed packages,
it calls the C<find_installed_apps()> first to populate it.
It will refuse to open multiple apps matched perhaps
by a regular expression in the package specification.

C<$params> is a HASH_REF which may or should contain:

=over 4

=item B<C<package>>

is required. It can either be
a scalar string with the exact package name
or a L<Regexp> object which is a compiled regular expression
created by e.g. C<qr/^\.com.+?\.settings$/i>. If a regular
expression, the call will fail if there is not
exactly one match.

=item B<C<lazy>>

is a flag to be passed on to L</find_installed_apps()>,
if needed, to denote whether to enquire
information about each package (app) at the time of this
call (set it to C<1>) or lazily, on a if-and-when-needed basis
(set it to C<0> which is the default). C<lazy> affects
all packages except those specified in C<packages>, if any. Default is C<1>.

=item B<C<force-reload-apps-list'>>

is a flag to be passed on to L</find_installed_apps()>,
if needed, and can be set to 1 to
erase previous packages information and start fresh. Default is C<0>.

=back

It returns a HASH_REF of matched packages names (keys) along
with enquired information (as a L<Android::ElectricSheep::Automator::AppProperties>
object). At the moment, because C<open_app()> allows opening only a single app,
this hash will contain only one entry unless we allow opening multiple
apps (e.g. via a regex which it is already supported) in the future.

=item close_app($params)

It closes the package specified in C<$params>
on the current device. If there are
no entries yet in the list of installed packages,
it calls the C<find_installed_apps()> first to populate it.
It will refuse to close multiple apps matched perhaps
by a regular expression in the package specification.

C<$params> is a HASH_REF which may or should contain:

=over 4

=item B<C<package>>

is required. It can either be
a scalar string with the exact package name
or a L<Regexp> object which is a compiled regular expression
created by e.g. C<qr/^\.com.+?\.settings$/i>. If a regular
expression, the call will fail if there is not
exactly one match.

=item B<C<lazy>>

is a flag to be passed on to L</find_installed_apps()>,
if needed, to denote whether to enquire
information about each package (app) at the time of this
call (set it to C<1>) or lazily, on a if-and-when-needed basis
(set it to C<0> which is the default). C<lazy> affects
all packages except those specified in C<packages>, if any. Default is C<1>.

=item B<C<force-reload-apps-list'>>

is a flag to be passed on to L</find_installed_apps()>,
if needed, and can be set to 1 to
erase previous packages information and start fresh. Default is C<0>.

=back

It returns a HASH_REF of matched packages names (keys) along
with enquired information (as a L<Android::ElectricSheep::Automator::AppProperties>
object). At the moment, because C<close_app()> allows closing only a single app,
this hash will contain only one entry unless we allow closing multiple
apps (e.g. via a regex which it is already supported) in the future.

=back

=head1 SCRIPTS

For convenience, a few simple scripts are provided:

=over 2

=item B<C<script/electric-sheep-find-installed-apps.pl>>

Find all install packages in the connected device. E.g.

C<< script/electric-sheep-find-installed-apps.pl --configfile config/myapp.conf --device Pixel_2_API_30_x86_ --output myapps.json >>

C<< script/electric-sheep-find-installed-apps.pl --configfile config/myapp.conf --device Pixel_2_API_30_x86_ --output myapps.json --fast >>


=item B<C<script/electric-sheep-open-app.pl>>

Open an app by its exact name or a keyword matching it (uniquely):

C<< script/electric-sheep-open-app.pl --configfile config/myapp.conf --name com.android.settings >>

C<< script/electric-sheep-open-app.pl --configfile config/myapp.conf --keyword 'clock' >>

Note that it constructs a regular expression from escaped user input.

=item B<C<script/electric-sheep-close-app.pl>>

Close an app by its exact name or a keyword matching it (uniquely):

C<< script/electric-sheep-close-app.pl --configfile config/myapp.conf --name com.android.settings >>

C<< script/electric-sheep-close-app.pl --configfile config/myapp.conf --keyword 'clock' >>

Note that it constructs a regular expression from escaped user input.

=item B<C<script/electric-sheep-dump-ui.pl>>

Dump the current screen UI as XML to STDOUT or to a file:

C<< script/electric-sheep-dump-ui.pl --configfile config/myapp.conf --output ui.xml >>

Note that it constructs a regular expression from escaped user input.

=item B<C<script/electric-sheep-dump-current-location.pl>>

Dump the GPS / geo-location position for the device from its various providers, if enabled.

C<< script/electric-sheep-dump-current-location.pl --configfile config/myapp.conf --output geolocation.json >>

=item B<C<script/electric-sheep-emulator-geofix.pl>>

Set the GPS / geo-location position to the specified coordinates.

C<< script/electric-sheep-dump-ui.pl --configfile config/myapp.conf --latitude 12.3 --longitude 45.6 >>

=item B<C<script/electric-sheep-dump-screen-shot.pl>>

Take a screenshot of the device (current screen) and save to a PNG file.

C<< script/electric-sheep-dump-screen-shot.pl --configfile config/myapp.conf --output screenshot.png >>

=item B<C<script/electric-sheep-dump-screen-video.pl>>

Record a video of the device's current screen and save to an MP4 file.

C<< script/electric-sheep-dump-screen-video.pl --configfile config/myapp.conf --output video.mp4 --time-limit 30 >>

=item B<C<script/electric-sheep-viber-send-message.pl>>

Send a message using the Viber app.

C<< script/electric-sheep-viber-send-message.pl --message 'hello%sthere' --recipient 'george' --configfile config/myapp.conf --device Pixel_2_API_30_x86_>>

This one saves a lot of debugging information to C<debug> which can be used to
deal with special cases or different versions of Viber:

C<< script/electric-sheep-viber-send-message.pl --outbase debug --verbosity 1 --message 'hello%sthere' --recipient 'george' --configfile config/myapp.conf --device Pixel_2_API_30_x86_>>

=back

=head1 TESTING

The normal tests under C<t/>, initiated with C<make test>,
are quite limited in scope because they do not assume
a connected device. That is, they do not check any
functions which require interaction with a connected
device.

The I<live tests> under C<xt/live>, initiated with
C<make livetest>, require
an Android device connected to your desktop on which
you installed this package and on which you are doing the testing.
This suffices to be an emulator. It can also be a real Android
phone but testing
with your smartphone is not a good idea, please do not do this,
unless it is some phone which you do not store important data.

So, prior to C<make livetest> make sure you have an android
emulator up and running with, for example,
C<emulator -avd Pixel_2_API_30_x86_> . See section
L<Android Emulators> for how to install, list and run them
buggers.

Testing will not send any messages via the device's apps.
E.g. the plugin L<Android::ElectricSheep::Automator::Plugins::Apps::Viber>
will not send a message via Viber but it will mock it.

The live tests will sometimes fail because, so far,
something unexpected happened in the device. For example,
in testing sending input text to a text-edit widget,
the calendar will be opened and a new entry will be added
and its text-edit widget will be targeted. Well, sometimes
the calendar app will give you some notification
on startup and this messes up with the focus.
Other times, the OS will detect that some app is taking too
long to launch and pops up a notification about
"I<something is not responding, shall I close it>".
This steals the focus and sometimes it causes
the tests to fail.

=head1 PREREQUISITES

=head2 Android Studio

This is not a prerequisite but it is
highly recommended to install
(from L<https://developer.android.com/studio>)
on your desktop computer because it contains
all the executables you will need,
saved in a well documented file system hierarchy,
which can then be accessed from the command line.

Additionally, Android Studio offers possibly the
easiest way to create Android Virtual Devices (AVD) which emulate
an Android phone of various specifications.
I mention this because one can install apps
on an AVD and control them from your desktop
as long as you are able to receive sms verification
codes from a real phone. This is great for
experimenting without pluggin in your real
smartphone on your desktop.

The bottom line is that by installing Android Studio,
you have all the executables you need for running things
from the command line and, additionally, you have
the easiest way for creating Android
Virtual Devices, which emulate Android devices: phones,
tablets, automotive displays. Once you have this set up, you
will not need to open Android Studio ever again unless you
want to update your kit. All the functionality
will be accessible from the command line.

=head2 ADB

Android Debug Bridge (ADB) is the program
which communicates with your smartphone or
an Android Virtual Device from
your desktop (Linux, osx and the unnamed C<0$>).

If you do not want to install Android Studio, the C<adb> executable
is included in the package called
"Android SDK Platform Tools" available from
the Android official site, here:
L<https://developer.android.com/tools/releases/platform-tools#downloads>

You will need the C<adb> executable to be on your path
or specify its fullpath in the configuration file
supplied to L<Android::ElectricSheep::Automator>'s constructor.

=head2 USB Debugging

The targeted smartphone must have "USB Debugging" enabled
via the "Developer mode".
This is not
to be confused with 'rooted' or 'jailbroken' modes, none of
these are required for experimenting with the current module.

In order to enable "USB Debugging", you need
to set the smartphone to enter "Developer" mode by
following this procedure:

Go to C<Settings-E<gt>System-E<gt>About Phone>
Tap on C<Build Number> 7 times [sic!].
Enter your phone pin and you are in developer mode.

You can exit Developer Mode by going to
C<Settings-E<gt>System-E<gt>Developer> and turn it off.
It is highly advised to turn off Developer Mode
for everyday use of your phone.
B<Do not connect your smartphone
to public WIFI networks with Developer Mode ON>.

B<Do not leave home with Developer Mode ON>.

Once you have enabled "USB Debugging", you have
two options for making your device visible to
your desktop and, consequently, to ADB and to this module:

=over 4

=item connect your android device via a USB cable
to your desktop computer. I am not sure if you also
need to tap on the USB charging options and allow
"Transfer Files".

=item connect your device to the same WIFI network
as your desktop computer. Then follow instructions
from, e.g., here L<https://developer.android.com>.
This requires a newer Android version.

=back

=head2 Android Emulators

It is possible to do most things your
smartphone does with an Android Virtual Device.
You can install apps on the the virtual device which
you can register by supplying your real smartphone
number.

List all virtual devices currently available
in your desktop computer,  with C<emulator -list-avds>
which outputs something like:

    Pixel_2_API_27_x86_
    Pixel_2_API_30_x86_

Start a virtual device with C<emulator -avd Pixel_2_API_30_x86_>

And hey, you have an android phone running on your
desktop in its own space, able to access the network
but not the telephone network (no SIM card).

It is possible to create a virtual device
from the command line.
But perhaps it is easier if you download Android Studio
from: L<https://developer.android.com/studio> and follow
the setup there using the GUI. You will need to do this just
once for creating the device, you can then uninstall Android Studio.

Android Studio will download all the
required files and will create some Android Virtual
Devices (the "emulators") for you. It will also be easy to
update your stack in the future. Once you have done the above,
you no longer need to run Android Studio except perhaps for
checking for updates and B<all the required executables by this
package will be available from the command line>.

Otherwise, download "Android SDK Platform Tools" available from
the Android official site, here:
L<https://developer.android.com/tools/releases/platform-tools#downloads>
(this download is mentioned in L<ADB> if you already fetched it).

Fetch the required packages with this command:

C<sdkmanager --sdk_root=/usr/local/android-sdk  "platform-tools" "platforms;android-30" "cmdline-tools;latest" "emulator">

Note that C<sdkmanager --list> will list the latest android versions etc.

Now you should have access to C<avdmanager> executable
(it should be located here: C</usr/local/android-sdk/cmdline-tools/latest/bin/avdmanager>)
which you can use to create an emulator.

List all available android virtual devices you can create: C<avdmanager list target>

List all available devices you can emulate: C<avdmanager list device>

List all available devices you have created already: C<avdmanager list avd>

Create virtual device: C<avdmanager create avd -d "Nexus 6" -n myavd -k "system-images;android-29;google_apis;x86">

See L<https://stackoverflow.com/a/77599934>

=head1 USING YOUR REAL SMARTPHONE

Using your real smartphone
with such a powerful tool may not be such
a good idea.

One can only imagine what
kind of viruses MICROSOFT WINDOWS can pass on to an
Android device connected to it. Refrain from doing
so unless you are using a more secure OS.

Start with an emulator.

=head1 WILL ANYTHING BE INSTALLED ON THE DEVICE?

Absolutely NOTHING!

This package
B<does not mess with the connected device,
neither it installs anything on it
neither it modifies
any of its settings>. Unless the user explicitly
does something, e.g. explicitly
a user installs / uninstalls apps
programmatically using this package.

Unlike this Python library:
L<https://github.com/openatx/uiautomator2>,
(not to be confused with google's namesake),
which sneakily installs their ADB server to your device!


=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-Android-ElectricSheep-Automator at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Android-ElectricSheep-Automator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Android::ElectricSheep::Automator


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Android-ElectricSheep-Automator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Android-ElectricSheep-Automator>

=item * Search CPAN

L<https://metacpan.org/release/Android-ElectricSheep-Automator>

=back

=head1 SEE ALSO

=over 4

=item * L<Android::ADB> is a thin wrapper of the C<adb> command
created by Marius Gavrilescu, C<marius@ieval.ro>.
It is used by current module, albeit modified.

=back

=head1 HUGS

=over 4

=item * Πτηνού, my chicken now laying in the big coop in the sky ...

=back


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Andreas Hadjiprocopis.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Android::ElectricSheep::Automator
