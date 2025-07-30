package Android::ElectricSheep::Automator::AppProperties;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.06';

use Mojo::Log;
use Config::JSON::Enhanced;
use XML::XPath;
use XML::LibXML;

use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

use overload ( '""'  => \&toString );

sub new {
	my $class = $_[0];
	my $params = $_[1] // {};

        my $parent = ( caller(1) )[3] || "N/A";
        my $whoami = ( caller(0) )[3];

	my $self = {
		'_private' => {
			'logger-object' => undef,
			'verbosity' => 0,
			'mother' => 0,
		},
		'data' => {
			# both are extracted from pkg=Package{3d33653 com.viber.voip}
			'packageName' => '',
			'packageId' => '',
			'codePath' => '',
			'resourcePath' => '',
			'applicationInfo' => '',
			'dataDir' => '',
			'versionCode' => '',
			'versionName' => '',
			'flags' => [],
			'privateFlags' => [],
			'pkgFlags' => [],
			'usesOptionalLibraries' => [],
			'usesLibraryFiles' => [],
			'timeStamp' => '',
			'firstInstallTime' => '',
			'lastUpdateTime' => '',
			'signatures' => '',
			'requestedPermissions' => [], # requested permissions
			'installPermissions' => [],
			'runtimePermissions' => [],
			'declaredPermissions' => [],
			'enabledComponents' => [],

			# activities
			# each item is a hash with name, fully qualified name etc.
			'MainActivity' => {}, # <<< this is an item as well if found
			'MainActivities' => [], # only those marked as .MAIN and .LAUNCHER
			'activities' => [], # all of them
		}
	};
	bless $self => $class;

	# we need a mother object (Android::ElectricSheep::Automator)
	if( (! exists $params->{'mother'})
	 || (! defined $params->{'mother'})
	 || (! defined $params->{'mother'}->adb())
	){ print STDERR "${whoami} (via $parent), line ".__LINE__." : error, input parameter 'mother' with our parent Android::ElectricSheep::Automator object was not specified.\n"; return undef }
	$self->{'_private'}->{'mother'} = $params->{'mother'};
	# we now have a mother

	if( exists $params->{'logger-object'} ){
		$self->{'_private'}->{'logger-object'} = $params->{'logger-object'}
	} else { $self->{'_private'}->{'logger-object'} = $self->mother->log }
	# we now have a log
	my $log = $self->log;

	if( exists $params->{'verbosity'} ){
		$self->{'_private'}->{'verbosity'} = $params->{'verbosity'}
	} else { $self->{'_private'}->{'verbosity'} = $self->mother->verbosity }
	# we now have verbosity
	my $verbosity = $self->verbosity;

	# caller can specify some initial data to load
	# OR caller can specify a string which is the output of a dumpsys (for 1 package)
	# to parse it
	# else caller must run ->enquire() to enquire the real device at a later time
	if( exists $params->{'data'} ){
		my $d = $self->{'data'}; 
		my $p = $params->{'data'};
		for my $k (sort keys %$d){
			if( exists($p->{$k}) && defined($p->{$k}) ){
				if( $self->set($k, $p->{$k}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'set()'." has failed for input parameter '$k', is its type as expected (".ref($d->{$k}).")?"); return undef }
			}
		}
	} elsif( exists $params->{'package'} ){
		# we have a package name, we will enquire about it and we
		# fill us up with its info
		if( 1 == $self->enquire({'package' => $params->{'package'}}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to enquire package '".$params->{'package'}."' (call to ".'enquire()'." has failed)."); return undef }
	}

	return $self;
}

# this is a factory method (static) which first does:
#   adb shell 'dumpsys package packages  #<< 1 operation
# to find all package names installed on device.
# If 'lazy'==1 then it stops there, returning only the package names
# (and not AppProperties associated with each package name).
# If 'lazy'==0 then for each package installed on device OR each
# package the caller specified ('packages'), it creates an
# AppProperties object (which does a dumpsys for each package name)
# filled up with info, like MainActivity, permissions etc.
# If 'packages' it was specified, then a list of ALL packages
# installed on device will be returned where those in 'packages'
# will have an AppProperties object associated with them. The rest
# will have an undef value.
# In the case where 'packages' was specified, 'lazy' value
# will affect only those packages not in 'packages'.
# If no 'packages' were specified then a hash of all installed
# packages will be returned. With:
#   1. If 'lazy'==1 then the values will be undef.
#   2. If 'lazy'==0 then each package will have an AppProperties value
#   associated with it. This can be slow (a few seconds) because
#   it does a dumpsys for each package.
# Default 'lazy' value is 1. And 'lazy'=0 for 'packages'.
# Input parameters:
#   'packages' => 'packagename' or regex (e.g. qr//) or [...] or { ...} :
#          optionally specify one or more packages to load non-lazily, all other
#          packages will be loaded lazily. Default is to load all packages lazily.
#          an item in 'packages' can be a string for exact package name match or
#          a compiled regex (qr//).
#          NOTE: at first all packages will be listed and no AppProperties will
#	   be created unless 'lazy'==0
#          Therefore specifying 'packages' means instantiate their
#	   AppProperties object, irrespective of the 'lazy' parameter.
#   'lazy' => 0 or 1 : optionally specify whether to load the 'packages' lazily
#          which means to have their name in the returned hash but the value
#          (the AppProperties object) will be undef, leaving instantiation for when needed.
#	   Default is lazy=1 (and lazy=0 for those items in 'packages')
#          NOTE: lazy will be 0 for the packages specified in 'packages' if any.
#   So either specify lazy=0 for getting info on all packages installed (takes some time!)
#   or set 'packages' to include those package names you want non-lazy, letting all other lazy.
# It returns undef on failure
# It returns %{ AppProperties objects } keyed on the app name (packageName),
#   on success. The values of the hash can be undef if lazy>0
#   meaning that they will be left to be enquired when someone needs them
#   e.g. in an open_app() call.
sub enquire_installed_apps_factory {
	my $params = $_[0] // {};

        my $parent = ( caller(1) )[3] || "N/A";
        my $whoami = ( caller(0) )[3];

	# we need a mother object (Android::ElectricSheep::Automator)
	if( (! exists $params->{'mother'})
	 || (! defined $params->{'mother'})
	 || (! defined $params->{'mother'}->adb())
	){ print STDERR "${whoami} (via $parent), line ".__LINE__." : error, input parameter 'mother' with our parent Android::ElectricSheep::Automator object was not specified.\n"; return undef }
	my $mother = $params->{'mother'};
	# we now have a mother

	my $log = $mother->log;
	my $verbosity = $mother->verbosity;

	# default is to be lazy (except for 'packages' if any)
	my $lazy = (exists($params->{'lazy'}) && defined($params->{'lazy'})) ? $params->{'lazy'} : 1;

	# if the user has specified packages then we will load just those non-lazily
	my ($packages, @packages_arr);
	if( exists($params->{'packages'}) && defined($packages=$params->{'packages'}) ){
		# packages can be a single package name
		my $rr = ref($packages);
		if( ($rr eq '') || ($rr eq 'Regexp') ){ @packages_arr = ($packages) }
		elsif( $rr eq 'ARRAY' ){ @packages_arr = @$packages }
		elsif( $rr eq 'HASH' ){ @packages_arr = ( map { $_ } grep { $packages->{$_} > 0 } keys %$packages ) }
		else { $log->error("${whoami} (via $parent), line ".__LINE__." : error, input parameter 'packages' must be a scalar string (for specifying just one package) or a regexp (Regexp type for compiled (".'qr//'.") regexes or an ARRAYref or a HASHref of package names and not '$rr'."); return undef }
	}
	# by now we have packages as a HASHref or undef and they can contain regex or string package names.

	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : called ...") }

	# NOTE
	#   dumpsys package packages
	# and 
	#   dumpsys package com.example.xyz 
	# will yield different things for the package com.example.xyz 
	# we need to enquire twice, 1 for all the package names
	# 2 for the full content of the package info, including activities
	# we will dumpsys specifically for that package

	# here we could also save to a file on device and then
	# fetch it locally. We will do that if there are problems
	# getting the dump from STDOUT
	my @cmd = ('dumpsys', 'package', 'packages');
	my $res = $mother->adb->shell(@cmd);
	if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return undef }
	if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nsSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return undef }
	my $content = $res->[1];

	my %apps;
	while( $content =~ /^\s{2}Package\s+\[(.+?)\]\s+\(.+?\)\:[\r\n](.+?)(?:[\r\n]\s{2}[^ ]|[\r\n]$|\z)/smg ){
		# if you want the package content:
		#while( $content =~ /^(\s{2}Package\s+\[(.+?)\]\s+\(.+?\)\:[\r\n].+?)(?:[\r\n]\s{2}[^ ]|[\r\n]$|\z)/smg ){
		#my $package_contents = $1; and name $2
		my $package_name = $1;
		# we will be lazy
		my $is_this_lazy = $lazy;
		if( $lazy == 1 ){
			for my $ap (@packages_arr){
				if( ref($ap) eq '' ){
					if( $package_name eq $ap ){ $is_this_lazy = 0; last }
				} else {
					if( $package_name =~ $ap ){ $is_this_lazy = 0; last }
				}
			}
		}
		if( $is_this_lazy == 0 ){
			my $app = Android::ElectricSheep::Automator::AppProperties->new({
				'package' => $package_name,
				'mother' => $mother,
			});
			if( ! defined $app ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'Android::ElectricSheep::Automator::AppProperties->new()'." has failed."); return undef }
			if( $verbosity > 1 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : enquired app '".$app->get('packageName')."' successfully and instantiated its AppProperties object.") }
			$apps{$package_name} = $app;
		} else {
			$apps{$package_name} = undef; # <<< lazy instantiate if&when needed
			if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : registered installed app '${package_name}' successfully (but not instantiated AppProperties).") }
		}
	}

	# done
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : enquired ".scalar(keys %apps)." apps.") }
	return \%apps;
}

# does a adb shell dumpsys and reads various things from it
# it may also do a adb shell wm density
# returns 0 on success, 1 on failure
sub enquire {
	my ($self, $params) = @_;
	$params //= {};

        my $parent = ( caller(1) )[3] || "N/A";
        my $whoami = ( caller(0) )[3];
	my $log = $self->log;
	my $verbosity = $self->verbosity;

	# NOTE
	#   dumpsys package packages
	# and 
	#   dumpsys package com.example.xyz 
	# will yield different things for the package com.example.xyz 
	# we need to enquire twice, 1 for all the package names
	# 2 for the full content of the package info, including activities
	# we will dumpsys specifically for that package
	my $package;
	if( ! exists($params->{'package'}) || ! defined($package=$params->{'package'}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, input parameter 'package' (the package name e.g. com.example.calendar) was not specified. If you want to enquire all installed apps, use the factory method ".'enquire_installed_apps_factory()'." in current package. A package name is not required if you provide the dumpsys for a specific package via the 'string' parameter."); return 1 }

	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : package '${package}' : called ...") }

	# here we could also save to a file on device and then
	# fetch it locally. We will do that if there are problems
	# getting the dump from STDOUT
	my @cmd = ('dumpsys', 'package', $package);
	my $res = $self->adb->shell(@cmd);
	if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return undef }
	if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nsSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return undef }
	my $content = $res->[1];

	if( $content =~ /^\s{2}Package.+?\:[\r\n].+?\s{4}pkg=Package\{(.+?) (.+?)\}[\r\n]/sm ){
		$self->set('packageId', $1);
		$self->set('packageName', $2);
	} else { $log->error("${whoami} (via $parent), line ".__LINE__." : package '${package}' : error, failed to find 'packageName' and 'packageId'."); return 1 }

	if( $content =~ /^\s{2}Package.+?\:[\r\n].+?\s{4}codePath=(.+?)[\r\n]/sm ){
		$self->set('codePath', $1);
	} else { $log->error("${whoami} (via $parent), line ".__LINE__." : package '${package}' : error, failed to find 'codePath'."); return 1 }

	if( $content =~ /^\s{2}Package.+?\:[\r\n].+?\s{4}codePath=(.+?)[\r\n]/sm ){
		$self->set('codePath', $1);
	} else { $log->error("${whoami} (via $parent), line ".__LINE__." : package '${package}' : error, failed to find 'codePath'."); return 1 }

	if( $content =~ /^\s{2}Package.+?\:[\r\n].+?\s{4}resourcePath=(.+?)[\r\n]/sm ){
		$self->set('resourcePath', $1);
	} else { $log->error("${whoami} (via $parent), line ".__LINE__." : package '${package}' : error, failed to find 'resourcePath'."); return 1 }

	if( $content =~ /^\s{2}Package.+?\:[\r\n].+?\s{4}codePath=(.+?)[\r\n]/sm ){
		$self->set('codePath', $1);
	} else { $log->error("${whoami} (via $parent), line ".__LINE__." : package '${package}' : error, failed to find 'codePath'."); return 1 }

	if( $content =~ /^\s{2}Package.+?\:[\r\n].+?\s{4}versionCode=(.+?)[\r\n]/sm ){
		$self->set('versionCode', $1);
	} else { $log->error("${whoami} (via $parent), line ".__LINE__." : package '${package}' : error, failed to find 'versionCode'."); return 1 }

	if( $content =~ /^\s{2}Package.+?\:[\r\n].+?\s{4}versionName=(.+?)[\r\n]/sm ){
		$self->set('versionName', $1);
	} else { $log->error("${whoami} (via $parent), line ".__LINE__." : package '${package}' : error, failed to find 'versionName'."); return 1 }

	if( $content =~ /^\s{2}Package.+?\:[\r\n].+?\s{4}flags=\[\s*(.+?)\s*\][\r\n]/sm ){
		$self->set('flags', [ split(/\s+/, $1) ]);
	} else { $log->error("${whoami} (via $parent), line ".__LINE__." : package '${package}' : error, failed to find 'flags'."); return 1 }

	if( $content =~ /^\s{2}Package.+?\:[\r\n].+?\s{4}privateFlags=\[\s*(.+?)\s*\][\r\n]/sm ){
		$self->set('privateFlags', [ split(/\s+/, $1) ]);
	} else { $log->error("${whoami} (via $parent), line ".__LINE__." : package '${package}' : error, failed to find 'privateFlags'."); return 1 }

	if( $content =~ /^\s{2}Package.+?\:[\r\n].+?\s{4}pkgFlags=\[\s*(.+?)\s*\][\r\n]/sm ){
		$self->set('pkgFlags', [ split(/\s+/, $1) ]);
	} else { $log->error("${whoami} (via $parent), line ".__LINE__." : package '${package}' : error, failed to find 'pkgFlags'."); return 1 }

	if( $content =~ /^\s{2}Package.+?\:[\r\n].+?\s{4}usesOptionalLibraries\:[\r\n](.+?)[\r\n]\s{4}[^ ]/sm ){
		$self->set('usesOptionalLibraries', [ map { $_ =~ s/\s+//g; $_ } split(/[\r\n]+/, $1) ]);
	} else { $self->set('usesOptionalLibraries', [] ); } # optional

	if( $content =~ /^\s{2}Package.+?\:[\r\n].+?\s{4}usesLibraryFiles\:[\r\n](.+?)[\r\n]\s{4}[^ ]/sm ){
		$self->set('usesLibraryFiles', [ map { $_ =~ s/\s+//g; $_ } split(/\[\r\n]+/, $1) ]);
	} else { $self->set('usesLibraryFiles', [] ); } # optional

	if( $content =~ /^\s{2}Package.+?\:[\r\n].+?\s{4}timeStamp=(.+?)[\r\n]/sm ){
		$self->set('timeStamp', $1);
	} else { $log->error("${whoami} (via $parent), line ".__LINE__." : package '${package}' : error, failed to find 'timeStamp'."); return 1 }

	if( $content =~ /^\s{2}Package.+?\:[\r\n].+?\s{4}firstInstallTime=(.+?)[\r\n]/sm ){
		$self->set('firstInstallTime', $1);
	} else { $log->error("${whoami} (via $parent), line ".__LINE__." : package '${package}' : error, failed to find 'firstInstallTime'."); return 1 }

	if( $content =~ /^\s{2}Package.+?\:[\r\n].+?\s{4}lastUpdateTime=(.+?)[\r\n]/sm ){
		$self->set('lastUpdateTime', $1);
	} else { $log->error("${whoami} (via $parent), line ".__LINE__." : package '${package}' : error, failed to find 'lastUpdateTime'."); return 1 }

	if( $content =~ /^\s{2}Package.+?\:[\r\n].+?\s{4}signatures=(.+?)[\r\n]/sm ){
		$self->set('signatures', $1);
	} else { $log->error("${whoami} (via $parent), line ".__LINE__." : package '${package}' : error, failed to find 'signatures'."); return 1 }

	if( $content =~ /^\s{2}Package.+?\:[\r\n].+?\s{4}declared permissions\:[\r\n]\s*(.+?)\s*[\r\n]\s{4}[^ ]/sm ){
		$self->set('declaredPermissions', [ split(/\s*[\r\n]+\s*/, $1) ]);
	} else { $self->set('declaredPermissions', [] ); } # optional

	if( $content =~ /^\s{2}Package.+?\:[\r\n].+?\s{4}requested permissions\:[\r\n]\s*(.+?)\s*[\r\n]\s{4}[^ ]/sm ){
		$self->set('requestedPermissions', [ split(/\s*[\r\n]+\s*/, $1) ]);
	} else { $self->set('requestedPermissions', [] ); } # optional

	if( $content =~ /^\s{2}Package.+?\:[\r\n].+?\s{4}install permissions\:[\r\n]\s*(.+?)\s*[\r\n]\s{4}[^ ]/sm ){
		$self->set('installPermissions', [ split(/\s*[\r\n]+\s*/, $1) ]);
	} else { $self->set('installPermissions', [] ); } # optional

	if( $content =~ /^\s{2}Package.+?\:[\r\n].+?\s{4}runtime permissions\:[\r\n]\s*(.+?)\s*[\r\n]\s{4}[^ ]/sm ){
		$self->set('runtimePermissions', [ split(/\s*[\r\n]+\s*/, $1) ]);
	} else { $self->set('runtimePermissions', [] ); } # optional

	if( $content =~ /^\s{2}Package.+?\:[\r\n].+?\s{4}enabledComponents\:[\r\n]\s*(.+?)(?:[\r\n]\s{6}[^\s]+|[\r\n]{2}|\z)/sm ){
		$self->set('enabledComponents', [ split(/\s*[\r\n]+\s*/, $1) ]);
	} else { $self->set('enabledComponents', [] ); } # optional

	# now parse all the activities
	if( $content =~ /^Activity Resolver Table:[\r\n].+?[\r\n]\s{6}android.intent.action.MAIN\:[\r\n](.+?)(?:[\r\n]\s{6}[^ ]|[\r\n]{2}|\z)/sm ){
		my $sc = $1;
		my @acts;
		while( $sc =~ /^\s{8}(.+?)[\r\n]\s{10}Action: "(.+?)"[\r\n]\s{10}Category: "(.+?)"/gsm ){
			my $nameall = $1;
			my $action = $2;
			my $category = $3;
			my ($fullname) = $nameall =~ /^.+?\s+(.+?)\s+/;
			my ($name) = $fullname =~ /\/(.+?)$/;
			push @acts, {
				'name-fully-qualified' => $fullname,
				'name' => $name,
				'name-all' => $nameall,
				'action' => $action,
				'category' => $category
			}
		}
		$self->set('activities', \@acts);
	} else { $self->set('activities', [] ); } # optional

	# parse the main activities only (1 or more)
	if( $content =~ /^Activity Resolver Table\:[\r\n].+?[\r\n]\s{6}android.intent.action.MAIN\:[\r\n](.+?)(?:[\r\n]\s{6}[^ ]|[\r\n]{2}|\z)/sm ){
		# we now have
		#         fb2df64 com.viber.voip/.WelcomeActivity filter a91c5cd
		#          Action: "android.intent.action.MAIN"
		#          Category: "android.intent.category.LAUNCHER"
		#        eb6c1f4 com.viber.voip/.settings.ui.SettingsHeadersActivity filter 9a11$
		#          Action: "android.intent.action.MAIN"
		#          Category: "android.intent.category.NOTIFICATION_PREFERENCES"
		# and we need the first, not the second
		my $sc = $1;
		my @acts;
		while( $sc =~ /^\s{8}(.+?)[\r\n]\s{10}Action\: "(android\.intent\.action\.MAIN)"[\r\n]\s{10}Category\: "(android\.intent\.category\.LAUNCHER)"/gsm ){
			my $nameall = $1;
			my $action = $2;
			my $category = $3;
			my ($fullname) = $nameall =~ /^.+?\s+(.+?)\s+/;
			my ($name) = $fullname =~ /\/(.+?)$/;
			push @acts, {
				'name-fully-qualified' => $fullname,
				'name' => $name,
				'name-all' => $nameall,
				'action' => $action,
				'category' => $category
			}
		}
		$self->set('MainActivities', \@acts);
	} else {
		$self->set('MainActivities', [] );
		if( $verbosity > 1 ){ $log->warn("${whoami} (via $parent), line ".__LINE__." : package '${package}' : warning, failed to find at least one MainActivity!") }
	}

	# choose one of the main activities for being the
	# one when we open the app.
	# Heuristic: just pick the shortest activity name which
	# does not contain dots except the startinh dot:
	my $ma = $self->get('MainActivities')->[0];
	my $l = length $ma->{'name'};
	for my $v (@{ $self->get('MainActivities') }){
		my $n = $v->{'name'};
		my $c = $n =~ tr/\.//;
		next if $c > 1;
		$c = length $n;
		if( $l > $c ){ $l = $c; $ma = $v };
	}
	$self->set('MainActivity', $ma);

	# done!
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : package '${package}' : done.") }
	return 0; # success
}

sub get { return $_[0]->has($_[1]) ? $_[0]->{'data'}->{$_[1]} : undef }
sub set {
	# set a new value even if it is not in our store,
	# but if it is, then check the types match
	if( exists($_[0]->{'data'}->{$_[1]})
	 && (ref($_[2]) ne ref($_[0]->{'data'}->{$_[1]}))
	){ $_[0]->log()->error(__PACKAGE__."::set(), line ".__LINE__." : error, the type of parameter '$_[1]' is '".ref($_[2])."' but '".ref($_[0]->{'data'}->{$_[1]})."' was expected."); return 1 }
	$_[0]->{'data'}->{$_[1]} = $_[2];
	return 0; # success
}
sub has { exists $_[0]->{'data'}->{$_[1]} }

sub toString {
	# unfortunately as a hash it is unsorted
	return perl2dump($_[0]->{'data'}, {terse=>1,pretty=>1});
}
sub toJSON { return perl2json($_[0]->{'data'}, {pretty=>1}); }
sub TO_JSON { return $_[0]->{'data'} }

sub log { return $_[0]->{'_private'}->{'logger-object'} }
sub verbosity { return $_[0]->{'_private'}->{'verbosity'} }
sub mother { return $_[0]->{'_private'}->{'mother'} }
sub adb { return $_[0]->mother->adb }

# only pod below
=pod

=head1 NAME

Android::ElectricSheep::Automator - The great new Android::ElectricSheep::Automator!

=head1 VERSION

Version 0.06


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Android::ElectricSheep::Automator;

    my $foo = Android::ElectricSheep::Automator->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1



=head2 function2


=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-android-adb-automator at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Android-ADB-Automator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Android::ElectricSheep::Automator


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Android-ADB-Automator>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Android-ADB-Automator>

=item * Search CPAN

L<https://metacpan.org/release/Android-ADB-Automator>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Andreas Hadjiprocopis.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Android::ElectricSheep::Automator
