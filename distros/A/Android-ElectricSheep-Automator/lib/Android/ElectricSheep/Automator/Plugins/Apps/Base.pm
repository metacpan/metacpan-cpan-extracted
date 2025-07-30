package Android::ElectricSheep::Automator::Plugins::Apps::Base;

# see also https://www.reddit.com/r/privacytoolsIO/comments/fit0tr/taking_almost_full_control_of_your_unrooted/
# swipe adb shell input touchscreen swipe 300 1200 100 1200 100

use 5.006;
use strict;
use warnings;

our $VERSION = '0.06';

use Mojo::Log;
use Config::JSON::Enhanced;
use File::Temp qw/tempfile/;
use Cwd;
use FindBin;

use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

use Android::ElectricSheep::Automator;
use Android::ElectricSheep::Automator::ScreenLayout;
use Android::ElectricSheep::Automator::XMLParsers;

my $_DEFAULT_CONFIG = <<'EODC';
</* comments are allowed */>
</* and <% vars %> and <% verbatim sections %> */>
{
	"Android::ElectricSheep::Automator" : {
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
	},
	"Android::ElectricSheep::Automator::Plugins::Apps::Viber" : {
	}
}
EODC

sub new {
	my $class = ref($_[0]) || $_[0];
	my $params = $_[1] // {};

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $self = {
		'_private' => {
			'child-class' => $class,
			'mother' => undef, # the Android::ElectricSheep::Automator object
			'confighash' => undef,
			'configfile' => '', # this should never be undef
		},
	};
	bless $self => $class;

	# this will read the confighash, check our params, confighash params, etc.
	# and also instantiate ua etc. and also do the verbosity etc.
	if( $self->init($params) ){ print STDERR __PACKAGE__." (via ".$self->child_class.") : ${whoami} (via $parent), line ".__LINE__." : error, call to init() has failed.\n"; return undef }

	# do module-specific init
	if( $self->init_module_specific($params) ){ print STDERR __PACKAGE__." (via ".$self->child_class.") : ${whoami} (via $parent), line ".__LINE__." : error, call to init_module_specific() has failed.\n"; return undef }

	# Now we have a logger
	my $log = $self->log();


	my $verbosity = $self->verbosity;

	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : done, success (verbosity is set to ".$self->verbosity." and cleanup to ".$self->cleanup.").") }

	return $self;
}

sub is_app_running {
	my ($self, $params) = @_;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	my $ret = $self->mother->is_app_running({'appname' => $self->appname});
	if( ! defined $ret ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'is_app_running()'." has failed."); return undef }
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : app '".$self->appname."' is ".($ret>0?"":"not")." running ...") }
	return $ret;
}
sub appname { return $_[0]->{'_private'}->{'appname'} }
sub open_app {
	my ($self, $params) = @_;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	my $packagename = $self->appname;
	my $ret = $self->mother->open_app({'package' => $packagename});
	if( ! defined $ret ){
		my $instapps = $self->mother->find_installed_apps();
		if( defined $instapps ){
			$log->error("All installed apps on current device:\n".join("\n  ".$_, sort keys %$instapps)."\n\n");
		}
		$log->error("${whoami} (via $parent), line ".__LINE__." : failed to open app '$packagename'.");
		return undef
	}
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : app '$packagename' is now opening ...") }
	return $ret;
}

sub close_app {
	my ($self, $params) = @_;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $log = $self->log();
	my $verbosity = $self->verbosity();

	my $packagename = $self->appname;
	my $ret = $self->mother->close_app({'package' => $packagename});
	if( ! defined $ret ){ $log->error("${whoami} (via $parent), line ".__LINE__." : failed to close app '$packagename'."); return undef }
	if( $verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : app '$packagename' is now closing ...") }
	return $ret;
}

sub adb { return $_[0]->{'_private'}->{'Android::ADB'} }
sub log { return $_[0]->{'_private'}->{'log'}->{'logger-object'} }
sub mother { return $_[0]->{'_private'}->{'mother'} }
sub child_class { return $_[0]->{'_private'}->{'child-class'} }

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
	my $log = $self->log();

	my $ch = Android::ElectricSheep::Automator::parse_configfile($infile, $log);
	if( ! defined $ch ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'Config::JSON::Enhanced::config2perl()'." has failed for configuration file '$infile'."); return undef }

	# set it in self, it will also do checks on required keys
	if( ! defined $self->confighash($ch) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, failed to load specified confighash, , there must be errors in the configuration."); return undef }

	$self->{'_private'}->{'configfile'} = $infile;

	return $infile #success
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

	print STDOUT "${whoami} (via $parent), line ".__LINE__." : called ...\n";

	# the confighash must contain a mother section: 'Android::ElectricSheep::Automator'
	# and a child section,
	# e.g. 'Android::ElectricSheep::Automator::Plugins::Apps::Viber'
	# check for both here:
	for ('Android::ElectricSheep::Automator', $self->child_class){
		if( ! exists($m->{$_}) || ! defined($m->{$_}) || (ref($m->{$_})ne'HASH') ){ print STDERR perl2dump($m)."${whoami} (via $parent), line ".__LINE__." : error, configuration (see above) does not have key '$_' or its value is not a HASHref.\n"; return undef }
	}

	my $x = 'Android::ElectricSheep::Automator';
	# we are storing specified confighash but first check it for some fields
	# required fields:
	for ('debug', 'logger'){
		if( ! exists($m->{$x}->{$_}) || ! defined($m->{$x}->{$_}) ){ print STDERR "${whoami} (via $parent), line ".__LINE__." : error, configuration does not have key '$x'->'$_'.\n"; return undef }
	}

	$x = $self->child_class;
	# we are storing specified confighash but first check it for some fields
	# required fields:
	#for ('debug', 'logger'){
	#	if( ! exists($m->{$x}->{$_}) || ! defined($m->{$x}->{$_}) ){ print STDERR "${whoami} (via $parent), line ".__LINE__." : error, configuration does not have key '$x'->'$_'.\n"; return undef }
	#}

	# ok!
	$self->{'_private'}->{'confighash'} = $m;
	return $m
}

# initialises
# returns 1 on failure, 0 on success
sub init {
	my ($self, $params) = @_;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	# we don't have a log yet

	if( exists($params->{'child-class'}) && defined($params->{'child-class'}) ){
		$self->{'_private'}->{'child-class'} = $params->{'child-class'};
	} else {  print STDERR "${whoami} (via $parent), line ".__LINE__." : error, input parameter 'child-class' was not specified, this is the Plugin class calling us, e.g. 'Android::ElectricSheep::Automator::Plugins::Apps::Viber'. At the moment this is not extracted from caller but needs to be specified explicitly by the caller (e.g. the Plugin class).\n"; return 1 }

	return 0 # success
}

# initialises module-specific things
# by now we already have read confighash and have logger, verbosity etc.
# returns 1 on failure, 0 on success
sub init_module_specific {
	my ($self, $params) = @_;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	# Confighash
	# first see if either user specified a config file or the default is present and read it,
	# then we will overwrite with user-specified params if any
	my ($configfile, $confighash);

	if( exists($params->{'configfile'}) && defined($configfile=$params->{'configfile'}) ){
		if( ! -f $configfile ){ print STDERR __PACKAGE__." (via ".$self->child_class.") : ${whoami} (via $parent), line ".__LINE__." : error, specified configfile '$configfile' does not exist or it is not a file.\n"; return 1 }
		# this reads, creates confighash and calls confighash() which will do all the tests
		if( ! defined $self->configfile($configfile) ){ print STDERR __PACKAGE__." (via ".$self->child_class.") : ${whoami} (via $parent), line ".__LINE__." : error, call to ".'configfile()'." has failed for configfile '$configfile'.\n"; return 1 }
		$confighash = $self->confighash();
	} elsif( exists($params->{'confighash'}) && defined($params->{'confighash'}) ){
		$confighash = $params->{'confighash'};
		# this sets the confighash and checks it too
		if( ! defined $self->confighash($confighash) ){ print STDERR __PACKAGE__." (via ".$self->child_class.") : ${whoami} (via $parent), line ".__LINE__." : error, call to ".'confighash()'." has failed.\n"; return 1 }
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

	if( exists($params->{'mother'}) && defined($params->{'mother'}) ){
		$self->{'_private'}->{'mother'} = $params->{'mother'};
	} else {
		# create the mother
		my $mparams = { %$params };
		delete $mparams->{'configfile'};
		$mparams->{'confighash'} =  $self->confighash->{'Android::ElectricSheep::Automator'};
		my $m = Android::ElectricSheep::Automator->new($mparams);
		if( ! defined $m ){ print STDERR __PACKAGE__." (via ".$self->child_class.") : ${whoami} (via $parent), line ".__LINE__." : error, failed to instantiate mother class ".'Android::ElectricSheep::Automator'.".\n"; return 1 }
		$self->{'_private'}->{'mother'} = $m;
	}
	# remove the mother class config, the confighash now is all ours
	$self->{'_private'}->{'confighash'} = $self->{'_private'}->{'confighash'}->{$self->child_class};

	# by now we have a confighash in self or died

	# for creating the logger: check
	#  1. params if they have logger or logfile
	#  2. our own confighash if it contains logfile
	#  3. if all else fails, take logger from mother which does exist even if vanilla

	if( exists($params->{'logger'}) && defined($params->{'logger'}) ){
		$self->{'_private'}->{'log'}->{'logger-object'} = $params->{'logger'};
		#print STDOUT "${whoami} (via $parent), line ".__LINE__." : using user-supplied logger object.\n";
	} elsif( exists($params->{'logfile'}) && defined($params->{'logfile'}) ){
		$self->{'_private'}->{'log'}->{'logger-object'} = Mojo::Log->new(path => $params->{'logfile'});
		#print STDOUT "${whoami} (via $parent), line ".__LINE__." : logging to file '".$params->{'logfile'}."'.\n";
	} elsif( exists($confighash->{'logger'}->{'logfile'}) && defined($confighash->{'logger'}->{'logfile'}) ){
		$self->{'_private'}->{'log'}->{'logger-object'} = Mojo::Log->new(path => $confighash->{'logger'}->{'logfile'});
		#print STDOUT "${whoami} (via $parent), line ".__LINE__." : logging to file '".$confighash->{'logger'}->{'logfile'}."'.\n";
	} else {
		$self->{'_private'}->{'log'}->{'logger-object'} = $self->mother()->log();
		#print STDOUT "${whoami} (via $parent), line ".__LINE__." : a vanilla logger has been inherited from mother.\n";
	}

	# Now we have a logger
	my $log = $self->log();
	$log->short(1);

	my $v;
	if( exists($params->{'verbosity'}) && defined($params->{'verbosity'}) ){
		$v = $params->{'verbosity'};
	} elsif( exists($confighash->{'debug'}) && exists($confighash->{'debug'}->{'verbosity'}) && defined($confighash->{'debug'}->{'verbosity'}) ){
		$v = $confighash->{'debug'}->{'verbosity'};
	} else {
		$v = $self->mother()->verbosity;
	}

	if( $self->verbosity($v) < 0 ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to 'verbosity()' has failed for value '$v'."); return 1 }

	if( exists($params->{'cleanup'}) && defined($params->{'cleanup'}) ){
		$v = $params->{'cleanup'};
	} elsif( exists($confighash->{'debug'}) && exists($confighash->{'debug'}->{'cleanup'}) && defined($confighash->{'debug'}->{'cleanup'}) ){
		$v = $confighash->{'debug'}->{'cleanup'};
	} else {
		$v = $self->mother()->cleanup;
	}
	if( $self->cleanup($v) < 0 ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to 'cleanup()' has failed for value '$v'."); return 1 }

	# optional params to overwrite confighash settings,
	# defaults exist above or in the configfile
	if( exists($params->{'verbosity'}) && defined($params->{'verbosity'}) ){ $self->verbosity($params->{'verbosity'}) } # later we will call verbosity()
	if( exists($params->{'cleanup'}) && defined($params->{'cleanup'}) ){ $self->cleanup($params->{'cleanup'}) }
	else { $self->cleanup($confighash->{'debug'}->{'cleanup'}) }

	if( $self->verbosity > 0 ){ $log->info("${whoami} (via $parent), line ".__LINE__." : ".__PACKAGE__." has been initialised ...") }

	return 0 # success
}

# only pod below
=pod

=head1 NAME

Android::ElectricSheep::Automator::Plugins::Apps::Base - base class for our plugins

=head1 VERSION

Version 0.06


=head1 SYNOPSIS

This is the parent class of all L<Android::ElectricSheep::Automator>
plugins. You do not need to override anything except perhaps the
constructor if you are going to be needing extra input parameters
to it. There is already one plugin provided L<Android::ElectricSheep::Automator::Plugins::Apps::Viber>
which can serve as an example for creating new plugins.
It is as simple as this:

    package Android::ElectricSheep::Automator::Plugins::Apps::MyNewPlugin;

    use parent 'Android::ElectricSheep::Automator::Plugins::Apps::Base';

    sub new {
            my ($class, $params) = @_;  
            my $self = $class->SUPER::new({
                    %$params,
                    'child-class' => $class,
            });
            # add some extra internal fields, e.g. the name of the app
            # we are dealing with
            $self->{'_private'}->{'appname'} = 'com.viber.voip';
    
            return $self;
    }
    # new methods
    # getter of the app name
    sub appname { return $_[0]->{'_private'}->{'appname'} }
    # any methods for controlling the app, e.g.
    sub open_viber_app {
        my ($self, $params) = @_;
        ...
    }
    ...

Then use the plugin as:

   use Android::ElectricSheep::Automator::Plugins::Apps::MyNewPlugin;
   my $vib = Android::ElectricSheep::Automator::Plugins::Apps::MyNewPlugin->new({
     configfile=>'config/plugins/viber.conf',
     'device-is-connected' => 1
   });
   $vib->open_app();
   $vib->is_app_running() or ...;
   $vib->send_message({recipient=>'My Notes', message=>'hello%sMonkees'});
   $vib->close_app();

=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-android-adb-automator at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Android-ADB-Automator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Android::ElectricSheep::Automator::Plugins::Apps::Base


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

1; # End of Android::ElectricSheep::Automator::Plugins::Apps::Base
