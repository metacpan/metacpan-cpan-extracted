# Parses a commandline packaged as a list (e.g. normally just pass @ARGV)
# and processes it into real objects for later use by various functions
# in the testontap universe
#
package App::TestOnTap::Args;

use strict;
use warnings;

use App::TestOnTap::Util qw(slashify expandAts);
use App::TestOnTap::Config;
use App::TestOnTap::Preprocess;
use App::TestOnTap::WorkDirManager;
use App::TestOnTap::OrderStrategy; 
use App::TestOnTap::PackInfo; 

use Archive::Zip qw(:ERROR_CODES);
use Getopt::Long qw(GetOptionsFromArray :config require_order no_ignore_case bundling);
use Pod::Usage;
use Pod::Simple::Search;
use Grep::Query;
use File::Spec;
use File::Path;
use File::Temp qw(tempdir);
use UUID::Tiny qw(:std);
use LWP::UserAgent;

# CTOR
#
sub new
{
	my $class = shift;
	my $version = shift;

	my $self = bless( { id => create_uuid_as_string() }, $class);
	$self->__parseArgv($version, @_);

	return $self;
}

sub __parseArgv
{
	my $self = shift;
	my $version = shift;
	my @argv = @_;
	
	my %rawOpts =
		(
			usage => 0,
			help => 0,
			manual => 0,
			version => 0,
			configuration => undef,		# no alternate config
			define => {},				# arbitrary key=value defines
			skip => undef,				# no skip filter
			include => undef,			# no include filter
			jobs => 1,					# run only one job at a time (no parallelism)
			order => undef,				# have no particular strategy for test order
			timer => 0,					# don't show timing output
			workdirectory => undef,		# explicit directory to use
			savedirectory => undef,		# don't save results (unless -archive is used)
			archive => 0,				# don't save results as archive
			v => 0,						# don't let through output from tests
			harness => 1,				# use the normal test harness
			merge => undef,				# ask the harness to merge stdout/stderr of tests
			
			# hidden
			#
			_help => 0,
			_pp => 0,
			_pp_script => undef,
			_pp_info => 0,
			_ignore_dependencies => 0,
		);
		
	my @specs =
		(
			'usage|?',
			'help|h',
			'manual',
			'version',
			'configuration|cfg=s',
			'define|D=s%',
			'skip=s',
			'include=s',
			'jobs=i',
			'order=s',
			'timer!',
			'workdirectory=s',
			'savedirectory=s',
			'archive',
			'v|verbose+',
			'harness!',
			'merge!',
			
			# hidden
			#
			'_help',
			'_pp',
			'_pp_script=s',
			'_pp_info',
			'_ignore_dependencies',
		);

	my $_argsPodName = 'App/TestOnTap/_Args._pod';
	my $_argsPodInput = Pod::Simple::Search->find($_argsPodName);
	my $argsPodName = 'App/TestOnTap/Args.pod';
	my $argsPodInput = Pod::Simple::Search->find($argsPodName);
	my $manualPodName = 'App/TestOnTap.pod';
	my $manualPodInput = Pod::Simple::Search->find($manualPodName);
	
	# for consistent error handling below, trap getopts problems
	# 
	eval
	{
		@argv = expandAts('.', @argv);
		$self->{fullargv} = [ @argv ];
		local $SIG{__WARN__} = sub { die(@_) };
		GetOptionsFromArray(\@argv, \%rawOpts, @specs)
	};
	if ($@)
	{
		pod2usage(-input => $argsPodInput, -message => "Failure parsing options:\n  $@", -exitval => 255, -verbose => 0);
	}

	# simple copies
	#
	$self->{$_} = $rawOpts{$_} foreach (qw(v archive timer harness));
	$self->{defines} = $rawOpts{define};

	# help with the hidden flags...
	#

	pod2usage(-input => $_argsPodInput, -exitval => 0, -verbose => 2, -noperldoc => 1) if $rawOpts{_help};

	# for the special selection of using --_pp* turn over to packinfo
	#
	my %packHelperOpts;
	foreach my $opt (keys(%rawOpts))
	{
		$packHelperOpts{$opt} = $rawOpts{$opt} if ($opt =~ /^_pp(_.+)?/ && $rawOpts{$opt});
	}
	if (keys(%packHelperOpts))
	{
		$packHelperOpts{verbose} = $rawOpts{v};
		App::TestOnTap::PackInfo::handle
										(
											\%packHelperOpts, 
											$version,
											$_argsPodName, $_argsPodInput,
											$argsPodName, $argsPodInput,
											$manualPodName, $manualPodInput
										);
		die("INTERNAL ERROR");
	}

	# if any of the doc switches made, display the pod
	#
	pod2usage(-input => $manualPodInput, -exitval => 0, -verbose => 2, -noperldoc => 1) if $rawOpts{manual};
	pod2usage(-input => $argsPodInput, -exitval => 0, -verbose => 2, -noperldoc => 1) if $rawOpts{help};
	pod2usage(-input => $argsPodInput, -exitval => 0, -verbose => 0) if $rawOpts{usage};
	pod2usage(-message => (slashify($0) . " version $version"), -exitval => 0, -verbose => 99, -sections => '_') if $rawOpts{version};

	# use the user skip or include filter for pruning the list of tests later
	#
	eval
	{
		if (defined($rawOpts{skip}) || defined($rawOpts{include}))
		{
			die("The options --skip and --include are mutually exclusive\n") if (defined($rawOpts{skip}) && defined($rawOpts{include}));
			if ($rawOpts{skip})
			{
				# try to compile the query first, to trigger any syntax problem now
				#
				Grep::Query->new($rawOpts{skip});
			
				# since we later want to select *included* files, 
				# we nefariously reverse the expression given
				#
				$self->{include} = Grep::Query->new("NOT ( $rawOpts{skip} )");
			}
			else
			{
				$self->{include} = Grep::Query->new($rawOpts{include});
			}
		}
	};
	if ($@)
	{
		$! = 255;
		die("Failure creating filter:\n  $@");
	}

	# make sure we have a valid jobs value
	#
	pod2usage(-message => "Invalid -jobs value: '$rawOpts{jobs}'", -exitval => 255, -verbose => 0) if $rawOpts{jobs} < 1;
	if ($rawOpts{jobs} < 1)
	{
		$! = 255;
		die("Invalid -jobs value: '$rawOpts{jobs}'\n");
	}
	$self->{jobs} = $rawOpts{jobs};
	
	# verify known order strategies
	#
	$self->{orderstrategy} = App::TestOnTap::OrderStrategy->new($rawOpts{order}) if $rawOpts{order};
	
	# set up savedir, if given - or, if archive is given fall back to current dir
	#
	if (defined($rawOpts{savedirectory}) || $rawOpts{archive})
	{
		eval
		{
			$self->{savedirectory} = slashify(File::Spec->rel2abs($rawOpts{savedirectory} || '.'));
			die("The -savedirectory '$self->{savedirectory}' exists but is not a directory\n") if (-e $self->{savedirectory} && !-d $self->{savedirectory});
			if (!-e $self->{savedirectory})
			{
				mkpath($self->{savedirectory}) or die("Failed to create -savedirectory '$self->{savedirectory}': $!\n");
			}
		};
		if ($@)
		{
			$! = 255;
			die("Failure setting up the save directory:\n  $@");
		}
	}

	# make sure we have the suite root and that it exists as directory
	#
	eval
	{
		die("No suite root provided!\n") unless @argv;
		$self->{suiteroot} = $self->__findSuiteRoot(shift(@argv));
	};
	if ($@)
	{
		$! = 255;
		die("Failure getting suite root directory:\n  $@");
	}

	# we want a config in the suite root
	#
	eval
	{
		$self->{config} = App::TestOnTap::Config->new($self->{suiteroot}, $rawOpts{configuration}, $rawOpts{_ignore_dependencies}); 
	};
	if ($@)
	{
		$! = 255;
		die("Failure handling config in '$self->{suiteroot}':\n  $@");
	}

	# set up the workdir manager
	#
	eval
	{
		$self->{workdirmgr} = App::TestOnTap::WorkDirManager->new($self, $rawOpts{workdirectory}, $self->{suiteroot});
	};
	if ($@)
	{
		$! = 255;
		die("Failure setting up the working directory:\n  $@");
	};

	# final sanity checks
	#
	if ($self->{jobs} > 1 && !$self->{config}->hasParallelizableRule())
	{
		warn("WARNING: No 'parallelizable' rule found ('--jobs $self->{jobs}' has no effect); all tests will run serially!\n");
	}

	# unless merge is explicitly set:
	# * default to merge if the results are saved in any way (to force stderr to the tap files)
	# * otherwise default to no merge
	#
	$self->{merge} =
		defined($rawOpts{merge})
			? $rawOpts{merge}
			: ($rawOpts{workdirectory} || $rawOpts{savedirectory} || $rawOpts{archive}) ? 1 : 0;

	# run preprocessing
	#
	$self->{preprocess} = App::TestOnTap::Preprocess->new($self->{config}->getPreprocessCmd(), $self, { %ENV }, \@argv);
}

sub getFullArgv
{
	my $self = shift;
	
	return $self->{fullargv};
}

sub getArgv
{
	my $self = shift;

	return $self->{preprocess}->getArgv();
}

sub getId
{
	my $self = shift;
	
	return $self->{id};
}

sub getJobs
{
	my $self = shift;
	
	return $self->{jobs};
}

sub getOrderStrategy
{
	my $self = shift;
	
	return $self->{orderstrategy};
}

sub getPreprocess
{
	my $self = shift;
	
	return $self->{preprocess};
}

sub getTimer
{
	my $self = shift;
	
	return $self->{timer};
}

sub getArchive
{
	my $self = shift;
	
	return $self->{archive};
}

sub getDefines
{
	my $self = shift;
	
	return $self->{defines};
}

sub getVerbose
{
	my $self = shift;
	
	return $self->{v};
}

sub getMerge
{
	my $self = shift;
	
	return $self->{merge};
}

sub getSuiteRoot
{
	my $self = shift;
	
	return $self->{suiteroot};
}

sub getSaveDir
{
	my $self = shift;
	
	return $self->{savedirectory};
}

sub getWorkDirManager
{
	my $self = shift;
	
	return $self->{workdirmgr};
}

sub getConfig
{
	my $self = shift;
	
	return $self->{config};
}

sub useHarness
{
	my $self = shift;
	
	return $self->{harness};
}

sub include
{
	my $self = shift;
	my $tests = shift;
	
	return
		$self->{include}
			? [ $self->{include}->qgrep(@$tests) ]
			: undef;
}

# PRIVATE
#

sub __findSuiteRoot
{
	my $self = shift;
	my $suiteroot = shift;

	if (-d $suiteroot)
	{
		$suiteroot = slashify(File::Spec->rel2abs($suiteroot));
	}
	else
	{
		die("Not a directory or zip archive: '$suiteroot'\n") unless $suiteroot =~ /\.zip$/i;
		my $zipfile = $suiteroot;
		my $tmpdir = slashify(tempdir("testontap-XXXX", TMPDIR => 1, CLEANUP => 1));

		if (!-f $suiteroot)
		{
			# maybe it's a url?
			# need to dl it before unpacking
			#
			my $localzip = slashify("$tmpdir/local.zip");
			print "Attempting to download '$suiteroot' => $localzip...\n" if $self->{v};
			my $ua = LWP::UserAgent->new();
			$ua->ssl_opts(verify_hostname => 0);
			my $response = $ua->get($suiteroot, ':content_file' => $localzip);
			if ($response->is_error() || !-f $localzip)
			{
				my $rc = $response->code();
				die("Treated '$suiteroot' as URL - failed to download : $rc\n");
			}
			$zipfile = $localzip;
		}
		
		print "Attempting to unpack '$zipfile'...\n" if $self->{v};
		my $zipErr;
		Archive::Zip::setErrorHandler(sub { $zipErr = $_[0]; chomp($zipErr) });
		my $zip = Archive::Zip->new($zipfile);
		die("Error when unpacking '$zipfile': $zipErr\n") if $zipErr;
		my @memberNames = $zip->memberNames();
		die("The zip archive '$suiteroot' is empty\n") unless @memberNames;
		my @rootEntries = grep(m#^[^/]+/?$#, @memberNames);
		die("The zip archive '$suiteroot' has more than one root entry\n") if scalar(@rootEntries) > 1;
		my $testSuiteDir = $rootEntries[0];
		die("The zip archive '$suiteroot' must have a test suite directory as root entry\n") unless $testSuiteDir =~ m#/$#;
		my $cfgFile = $testSuiteDir . App::TestOnTap::Config::getName();
		die("The zip archive '$suiteroot' must have a '$cfgFile' entry\n") unless grep(/^\Q$cfgFile\E$/, @memberNames);
		die("Failed to extract '$suiteroot': $!\n") unless $zip->extractTree('', $tmpdir) == AZ_OK;
		$suiteroot = slashify(File::Spec->rel2abs("$tmpdir/$testSuiteDir"));
		print "Unpacked '$suiteroot'\n" if $self->{v}; 
	}
	
	return $suiteroot;
}

1;
