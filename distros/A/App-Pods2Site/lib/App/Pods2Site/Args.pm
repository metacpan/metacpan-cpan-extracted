# Parses a commandline packaged as a list (e.g. normally just pass @ARGV)
# and processes it into real objects for later use by various functions
# in the Pods2Site universe
#
package App::Pods2Site::Args;

use strict;
use warnings;

use App::Pods2Site::Util qw(slashify trim readData writeData expandAts $IS_PACKED $IS_WINDOWS $SHELL_ARG_DELIM $PATH_SEP);
use App::Pods2Site::SiteBuilderFactory;

use Config;
use FindBin qw($RealBin $Script);
use Getopt::Long qw(GetOptionsFromArray :config require_order no_ignore_case bundling);
use File::Spec;
use File::Basename;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use Config qw(%Config);
use Pod::Usage;
use Pod::Simple::Search;
use List::MoreUtils qw(uniq);
use Grep::Query;
use POSIX;

# CTOR
#
sub new
{
	my $class = shift;
	my $version = shift;

	my $self = bless( {}, $class);
	$self->__parseArgv($version, @_);

	return $self;
}

sub getSiteDir
{
	my $self = shift;
	
	return $self->{sitedir};
}

sub getBinDirs
{
	my $self = shift;
	
	return @{$self->{bindirs}};
}

sub getLibDirs
{
	my $self = shift;
	
	return @{$self->{libdirs}};
}

sub getTitle
{
	my $self = shift;
	
	return $self->{title};
}

sub getStyle
{
	my $self = shift;
	
	return $self->{style};
}

sub getWorkDir
{
	my $self = shift;
	
	return $self->{workdir};
}

sub getGroupDefs
{
	my $self = shift;
	
	return $self->{groupdefs};
}

sub getCSS
{
	my $self = shift;
	
	return $self->{css};
}

sub getSiteBuilder
{
	my $self = shift;
	
	return $self->{sitebuilder};
}

sub isVerboseLevel
{
	my $self = shift;
	my $level = shift;
	
	return $self->{verbose} >= $level;	
}

# PRIVATE
#

sub __parseArgv
{
	my $self = shift;
	my $version = shift;
	my @argv = @_;

	# these options are persisted to the site
	# and can't be used when updating
	#	
	my @stickyOpts =
		qw
			(
				bindirectory
				libdirectory
				group
				css
				style
				title
			);
		
	my %rawOpts =
		(
			usage => 0,
			help => 0,
			manual => 0,
			v => 0,
			workdirectory => undef,
			quiet => 0,
			
			# hidden
			#
			_help => 0,
			_pp => 0,					# print basic PAR::Packer 'pp' command line
		);
		
	my @specs =
		(
			'usage|?',
			'help',
			'manual',
			'version',
			'v|verbose+',
			'workdirectory=s',
			'quiet',
			'bindirectory=s@',
			'libdirectory=s@',
			'group=s@',
			'css=s',
			'style=s',
			'title=s',
			
			# hidden
			#
			'_help',
			'_pp',
		);

	my $_argsPodName = 'App/Pods2Site/_Args.pod';
	my $_argsPodInput = Pod::Simple::Search->find($_argsPodName);
	my $argsPodName = 'App/Pods2Site/Args.pod';
	my $argsPodInput = Pod::Simple::Search->find($argsPodName);
	my $manualPodName = 'App/Pods2Site.pod';
	my $manualPodInput = Pod::Simple::Search->find($manualPodName);

	# for consistent error handling below, trap getopts problems
	# 
	eval
	{
		@argv = expandAts('.', @argv);
		local $SIG{__WARN__} = sub { die(@_) };
		GetOptionsFromArray(\@argv, \%rawOpts, @specs)
	};
	if ($@)
	{
		pod2usage(-input => $argsPodInput, -message => "Failure parsing options:\n  $@", -exitval => 255, -verbose => 0);
	}

	# help with the hidden flags...
	#
	pod2usage(-input => $_argsPodInput, -exitval => 0, -verbose => 2, -noperldoc => 1) if $rawOpts{_help};

	# for the special selection of using --_pp, print command line and exit
	#
	if ($rawOpts{_pp})
	{
		$self->__print_pp_cmdline
					(
						$version,
						$argsPodName, $argsPodInput,
						$manualPodName, $manualPodInput
					);
		exit(0);
	}

	# if any of the doc switches made, display the pod
	#
	pod2usage(-input => $manualPodInput, -exitval => 0, -verbose => 2, -noperldoc => 1) if $rawOpts{manual};
	pod2usage(-input => $argsPodInput, -exitval => 0, -verbose => 2, -noperldoc => 1) if $rawOpts{help};
	pod2usage(-input => $argsPodInput, -exitval => 0, -verbose => 0) if $rawOpts{usage};
	pod2usage(-message => slashify($0) . " version $App::Pods2Site::VERSION", -exitval => 0, -verbose => 99, -sections => '_') if $rawOpts{version};

	# if -quiet has been given, it trumps any verbosity
	#	
	$self->{verbose} = $rawOpts{quiet} ? -1 : $rawOpts{v};

	# manage the sitedir
	# assume we need to create it
	#
	my $newSiteDir = 1;
	my $sitedir = $self->__getSiteDir($argv[0]);
	die("You must provide a sitedir (use ':std' for a default location)\n") unless $sitedir;
	$sitedir = slashify(File::Spec->rel2abs($sitedir));
	if (-e $sitedir)
	{
		$newSiteDir = 0;
		
		# if the sitedir exists as a dir, our sticky opts better be found in it
		# otherwise it's not a sitedir
		#
		die("The output '$sitedir' exists, but is not a directory\n") unless -d $sitedir;
		my $savedOpts = readData($sitedir, 'opts');
		die("The sitedir '$sitedir' exists, but is missing our marker file\n") unless $savedOpts;

		# clean up any sticky opts given by the user
		#
		print "NOTE: updating '$sitedir' - reusing options used when created!\n" if $self->isVerboseLevel(0);
		foreach my $opt (@stickyOpts)
		{
			warn("WARNING: The option '$opt' ignored when updating the existing site '$sitedir'\n") if exists($rawOpts{$opt});
			delete($rawOpts{$opt});
		}
		%rawOpts = ( %rawOpts, %$savedOpts );
	}
	else
	{
		print "Creating '$sitedir'...\n" if $self->isVerboseLevel(0);
	}
	
	# fix up any user given bindir locations or get us the standard ones
	#
	my @bindirs = uniq($self->__getBinLocations($rawOpts{bindirectory}));
	warn("WARNING: No bin directories found\n") unless @bindirs;
	$self->{bindirs} = $rawOpts{bindirectory} = \@bindirs;

	# fix up any user given libdir locations or get us the standard ones
	#
	my @libdirs = uniq($self->__getLibLocations($rawOpts{libdirectory}));
	warn("WARNING: No lib directories found\n") unless @libdirs;
	$self->{libdirs} = $rawOpts{libdirectory} = \@libdirs;

	my $workdir;
	if ($rawOpts{workdirectory})
	{
		# if user specifies a workdir this implies that it should be kept
		# just make sure there is no such directory beforehand, and create it here
		# (similar to below; tempdir() will also create one)
		#
		$workdir = slashify(File::Spec->rel2abs($rawOpts{workdirectory}));
		die("The workdir '$workdir' already exists\n") if -e $workdir;
		make_path($workdir) or die("Failed to create workdir '$workdir': $!\n");
	}
	else
	{
		# create a temp dir; use automatic cleanup
		#
		$workdir = slashify(tempdir("pods2site-XXXX", TMPDIR => 1, CLEANUP => 1));
	}
	$self->{workdir} = $workdir;

	# Ensure we have group definitions, and test queries before storing
	# 
	my @rawGroupDefs  = $self->__getRawGroupDefs($rawOpts{group});
	my @groupDefs;
	my %groupsSeen;
	foreach my $rawGroupDef (@rawGroupDefs)
	{
		eval
		{
			die("Group definition not in form 'name=query': '$rawGroupDef'\n") unless $rawGroupDef =~ /^([^=]+)=(.+)/s;
			my ($name, $query) = (trim($1), trim($2));
			die("Group '$name' multiply defined\n") if $groupsSeen{$name};
			$groupsSeen{$name} = 1;
			push(@groupDefs, { name => $name, query => Grep::Query->new($query) });
		};
		pod2usage(-message => "Problem with group definition '$rawGroupDef':\n  $@", -exitval => 255, -verbose => 0) if $@;
	}
	$rawOpts{group} = \@rawGroupDefs;
	$self->{groupdefs} = \@groupDefs;

	# fix up any css path given by user
	#	
	if ($rawOpts{css})
	{
		my $css = slashify(File::Spec->rel2abs($rawOpts{css}));
		die("No such file: -css '$css'\n") unless -f $css;
		$self->{css} = $css;
	}

	$rawOpts{title} = $rawOpts{title} || ($Config{myuname} ? "Pods2Site : $Config{myuname}" : 'Pods2Site');
	$self->{title} = $rawOpts{title};
	
	$self->{style} = $rawOpts{style};
	my $sbf = App::Pods2Site::SiteBuilderFactory->new($rawOpts{style});
	$self->{style} = $sbf->getRealStyle();
	$self->{sitebuilder} = $sbf->createSiteBuilder();
	
	# if we need to create the site dir...
	#
	if ($newSiteDir)
	{	
		# ...do it and persist the sticky options
		#
		make_path($sitedir) || die("Failed to create sitedir '$sitedir': $!\n");
		my %opts2save = map { $_ => $rawOpts{$_} } @stickyOpts;
		writeData($sitedir, 'opts', \%opts2save);
	}
	
	$self->{sitedir} = $sitedir;
}

sub __getSiteDir
{
	my $self = shift;
	my $sitedir = shift;
	
	if ($sitedir && $sitedir eq ':std')
	{
		die("Sorry, don't have a ':std' directory when running a packed binary\n") if $IS_PACKED;
		$sitedir = slashify((dirname(dirname($^X)) . '/pods2site'));
	}
	
	return $sitedir;
}

sub __getRawGroupDefs
{
	my $self = shift;
	my $groupDefs = shift;
	
	my @newDefs = ($groupDefs && @$groupDefs) ? @$groupDefs :  ':std';
	my $ndx = 0;
	while ($ndx <= $#newDefs)
	{
		if ($newDefs[$ndx] =~ /^:/)
		{
			splice(@newDefs, $ndx, 1, $self->__getInternalRawGroupDefs($newDefs[$ndx]));
		}
		else
		{
			$ndx++;
		}
	}
	
	return @newDefs;
}

sub __getInternalRawGroupDefs
{
	my $self = shift;
	my $internal = shift;
	
	my @groupDefs;
	if ($internal eq ':std')
	{
		@groupDefs = qw(:std-core :std-scripts :std-pragmas :std-modules);
	}
	elsif ($internal eq ':std-core')
	{
		@groupDefs = <<'CORE',
			Core=
			/*
				Select any pods in library/pod locations that are named with prefix 'perl'
			*/
			type.eq(corepod)
CORE
	}
	elsif ($internal eq ':std-scripts')
	{
		@groupDefs = <<'SCRIPTS',
			Scripts=
			/*
				Assume all pods in bin locations are scripts. Also add the PAR::Packer
				'pp' pod; while there is a pp script it has no pod docs, they're in
				the toplevel pp.pm. 
			*/
			type.eq(bin) || name.eq(pp)
SCRIPTS
	}
	elsif ($internal eq ':std-pragmas')
	{
		@groupDefs = <<'PRAGMAS',
			Pragmas=
			/*
				Select any pods in library locations that are named with a lower-case
				initial in their package name and consider them pragmas.
				Avoid those pods picked up by the Core/Script groups. 
			*/
			type.eq(lib) &&
				name.regexp{^[a-z]} &&
				NOT name.eq(pp)
PRAGMAS
	}
	elsif ($internal eq ':std-modules')
	{
		@groupDefs = <<'MODULES'
			Modules=
			/*
				Any pods not selected by the other three are assumed to
				be 'normal' modules.
			*/
			NOT
				(
					type.eq(bin) ||
					type.eq(corepod) ||
					name.eq(pp) ||
					name.regexp{^[a-z]}
				)
MODULES
	}
	else
	{
		die("Unknown internal group definition: '$internal'\n");
	}
	
	return @groupDefs;
}

sub __getBinLocations
{
	my $self = shift;
	my $argLocs = shift;
	
	# if the user provided any bin locations, interpret them
	# otherwise return the default places
	#
	my @locs;
	if (defined($argLocs))
	{
		foreach my $loc (@$argLocs)
		{
			if (defined($loc) && length($loc) > 0)
			{
				if ($loc eq ':std')
				{
					push(@locs, $self->__getDefaultBinLocations());
				}
				elsif ($loc eq ':path')
				{
					push(@locs, split(/\Q$PATH_SEP\E/, $ENV{PATH}));
				}
				elsif ($loc eq ':none')
				{
					# do nothing
				}
				else
				{
					push(@locs, $loc) if -d $loc;
				}
			}
		}
	}
	else
	{
		@locs = $self->__getDefaultBinLocations();
	}

	# ensure all paths are absolute and clean
	#	
	$_ = slashify(File::Spec->rel2abs($_)) foreach (@locs);
	
	return @locs;
}

sub __getDefaultBinLocations
{
	my $self = shift;

	# a somewhat guessed list for Config keys for scripts...
	# note: order is important
	#
	return $self->__getConfigLocations
		(
			qw
				(
					installsitebin
					installsitescript
					installvendorbin
					installvendorscript
					installbin
					installscript
				)
		);
}

sub __getLibLocations
{
	my $self = shift;
	my $argLocs = shift;
	
	# if the user provided any lib locations, interpret them
	# otherwise return the default places
	#
	my @locs;
	if (defined($argLocs))
	{
		foreach my $loc (@$argLocs)
		{
			if (defined($loc) && length($loc) > 0)
			{
				if ($loc eq ':std')
				{
					push(@locs, $self->__getDefaultLibLocations());
				}
				elsif ($loc eq ':inc')
				{
					push(@locs, @INC);
				}
				elsif ($loc eq ':none')
				{
					# do nothing
				}
				else
				{
					push(@locs, $loc) if -d $loc;
				}
			}
		}
	}
	else
	{
		@locs = $self->__getDefaultLibLocations();
	}
	
	# ensure all paths are absolute and clean
	#	
	$_ = slashify(File::Spec->rel2abs($_)) foreach (@locs);

	return @locs;
}

sub __getDefaultLibLocations
{
	my $self = shift;
	
	# a somewhat guessed list for Config keys for lib locations...
	# note: order is important
	#
	return $self->__getConfigLocations
		(
			qw
				(
					installsitearch
					installsiteslib
					installvendorarch
					installvendorlib
					installarchlib
					installprivlib
				)
		);
}
sub __getConfigLocations
{
	my $self = shift;
	my @cfgnames = @_;

	# the keys don't always contain anything useful
	#
	my @locs;
	foreach my $loc (@cfgnames)
	{
		my $cfgloc = $Config{$loc};
		if (	defined($cfgloc)
			&&	length($cfgloc) > 0
			&& -d $cfgloc)
		{
			push(@locs, $cfgloc);
		}
	}	
	
	return @locs;
}

sub __print_pp_cmdline
{
	my $self = shift;
	my $version = shift;
	my $argsPodName = shift;
	my $argsPodInput = shift;
	my $manualPodName = shift;
	my $manualPodInput = shift;
	
	die("Sorry, you're already running a binary/packed instance\n") if $IS_PACKED;
	
	eval "require PAR::Packer";
	warn("Sorry, it appears PAR::Packer is not installed/working!\n") if $@;

	my $os = $IS_WINDOWS ? 'windows' : $^O;
	my $arch = (POSIX::uname())[4];
	my $exeSuffix = $IS_WINDOWS ? '.exe' : '';
	my $bnScript = basename($Script);
	my $output = "$bnScript-$version-$os-$arch$exeSuffix";
	my @liblocs = map { $_ ne '.' ? ('-I', slashify(File::Spec->rel2abs($_))) : () } @INC;
	my @cmd =
		(
			'pp',
			@liblocs,
			'-a', "$argsPodInput;lib/$argsPodName",
			'-a', "$manualPodInput;lib/$manualPodName",
			'-o', $output,
			slashify("$RealBin/$Script")
		);

	my $cmdline = '';
	$cmdline .= "$SHELL_ARG_DELIM$_$SHELL_ARG_DELIM " foreach (@cmd);
	chop($cmdline);
	print "$cmdline\n";
}

1;
