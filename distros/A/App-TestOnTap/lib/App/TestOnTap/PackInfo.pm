package App::TestOnTap::PackInfo;

use App::TestOnTap::Util qw(slashify $IS_WINDOWS $IS_PACKED $SHELL_ARG_DELIM $FILE_SEP);

use Config qw(myconfig);
use ExtUtils::Installed;
use File::Basename;
use File::Slurp qw(write_file);
use File::Spec;
use File::Temp qw(tempfile tempdir);
use FindBin qw($RealBin $RealScript);
use POSIX;

sub handle
{
	my $opts = shift; 
	my $version = shift;
	my $_argsPodName = shift;
	my $_argsPodInput = shift;
	my $argsPodName = shift;
	my $argsPodInput = shift;
	my $manualPodName = shift;
	my $manualPodInput = shift;

	die("Only one of --_pp, --_pp_script, --_pp_info allowed\n") if grep(/^_(pp)$/, keys(%$opts)) > 1;
	if    ($opts->{_pp})           { _pp($opts, $version, $_argsPodName, $_argsPodInput, $argsPodName, $argsPodInput, $manualPodName, $manualPodInput); }
	elsif ($opts->{_pp_script})    { _pp_script($opts, $version, $_argsPodName, $_argsPodInput, $argsPodName, $argsPodInput, $manualPodName, $manualPodInput); }
	elsif ($opts->{_pp_info})      { _pp_info($opts); }
	else { die("INTERNAL ERROR"); }
		
	exit(0);
}

sub _pp_script
{
	my $scriptFile = __internal_pp_script(@_);
	print "Wrote script '$scriptFile'\n";
}

sub _pp
{
	my $tmpDir = tempdir('testontap_ppscript_XXXX', TMPDIR => 1, CLEANUP => 1);
	$_[0]->{_pp_script} = "$tmpDir/testontap_pp.pl";
	my $scriptFile = __internal_pp_script(@_);
	system("$^X $SHELL_ARG_DELIM$scriptFile$SHELL_ARG_DELIM");
}

sub _pp_info
{
	my $opts = shift;

	die("Sorry, you're not running a binary/packed instance\n") unless $IS_PACKED;

	print "$0\n";
	foreach my $sec (qw(USERNAME HOSTNAME CONFIG ENV MODULES CMD))
	{
		print "### $sec BEGIN\n";
		print PAR::read_file("TESTONTAP_${sec}_FILE");
		print "### $sec END\n";
	}
}

###

sub __construct_outfilename
{
	my $version = shift;
	
	my $os = $IS_WINDOWS ? 'windows' : $^O;
	my $arch = (POSIX::uname())[4];
	my $exeSuffix = $IS_WINDOWS ? '.exe' : '';
	my $bnScript = basename($RealScript);
	
	return "$bnScript-$version-$os-$arch$exeSuffix";
}

sub __internal_pp_script
{
	my $opts = shift;
	my $version = shift;
	my $_argsPodName = shift;
	my $x__argsPodInput = slashify(File::Spec->rel2abs(shift), '/');
	my $argsPodName = shift;
	my $x_argsPodInput = slashify(File::Spec->rel2abs(shift), '/');
	my $manualPodName = shift;
	my $x_manualPodInput = slashify(File::Spec->rel2abs(shift), '/');

	die("Sorry, you're already running a binary/packed instance\n") if $IS_PACKED;
	
	my $scriptFile = slashify(File::Spec->rel2abs($opts->{_pp_script}));
	die("The path '$scriptFile' already exists\n") if -e $scriptFile;
	
	my $x_input = slashify("$RealBin/$RealScript", '/');
	my $x_output = __construct_outfilename($version);
	my $x_verbose = $opts->{verbose} ? 1 : 0;
	my $x_fsep = $FILE_SEP;
	$x_fsep .= "\\" if $x_fsep eq "\\";

	my $x_liblocs = "my \@liblocs;\n";
	foreach my $libloc (@INC)
	{
		next if ($libloc eq '.' || ref($libloc));
		$x_liblocs .= "push(\@liblocs, '-I', '" . slashify(File::Spec->rel2abs($libloc), '/') . "');\n";
	}
	chomp($x_liblocs);
	
	my $script = <<SCRIPT;
#! $^X
use strict;
use warnings;

use Config qw(myconfig);
use ExtUtils::Installed;
use File::Basename;
use File::Slurp qw(write_file);
use File::Spec;
use File::Temp qw(tempfile);
use Getopt::Long;
use Net::Domain qw(hostfqdn);

\$| = 1;

eval "require PAR::Packer";
die("Sorry, PAR:Packer is not installed/working!\\n") if \$@;

my \$IS_WINDOWS = \$^O eq 'MSWin32';

my \$_argsPodInput = slashify(File::Spec->rel2abs('$x__argsPodInput'));
my \$argsPodInput = slashify(File::Spec->rel2abs('$x_argsPodInput'));
my \$manualPodInput = slashify(File::Spec->rel2abs('$x_manualPodInput'));

my \$outfile = slashify(File::Spec->rel2abs('$x_output'));
my \$verbose = $x_verbose;
my \$debug = 0;
my \$info = 1;
GetOptions('outfile=s' => \\\$outfile, 'verbose!' => \\\$verbose, 'info!' => \\\$info, 'debug' => \\\$debug) || usage();
\$verbose = 1 if \$debug; 

my \$outdir = dirname(\$outfile);
die("The output directory doesn't exist: '\$outdir'\\n") unless -d \$outdir;
die("The outfile exists: '\$outfile'\\n") if -e \$outfile;

print "Getting username...\\n" if \$verbose;
my (undef, \$usernameFile) = tempfile('testontap_username_XXXX', TMPDIR => 1, UNLINK => 1);
if (\$info)
{
	my \$username = \$IS_WINDOWS ? getlogin() : scalar(getpwuid(\$<));
	write_file(\$usernameFile, "\$username\\n") || die("Failed to write '\$usernameFile': $!\\n");
}

print "Getting hostname...\\n" if \$verbose;
my (undef, \$hostnameFile) = tempfile('testontap_hostname_XXXX', TMPDIR => 1, UNLINK => 1);
if (\$info)
{
	my \$hostname = hostfqdn();
	write_file(\$hostnameFile, "\$hostname\\n") || die("Failed to write '\$hostnameFile': $!\\n");
}

print "Getting environment...\\n" if \$verbose;
my (undef, \$envFile) = tempfile('testontap_env_XXXX', TMPDIR => 1, UNLINK => 1);
if (\$info)
{
	my \$env = getEnv();
	write_file(\$envFile, \$env) || die("Failed to write '\$envFile': $!\\n");
}

print "Getting config...\\n" if \$verbose;
my (undef, \$configFile) = tempfile('testontap_config_XXXX', TMPDIR => 1, UNLINK => 1);
if (\$info)
{
	my \$config = myconfig();
	write_file(\$configFile, \$config) || die("Failed to write '\$configFile': \$!\\n");
}
 
print "Getting modules...\\n" if \$verbose;
my (undef, \$modulesFile) = tempfile('testontap_modules_XXXX', TMPDIR => 1, UNLINK => 1);
if (\$info)
{
	my \$modules = find_modules();
	write_file(\$modulesFile, \$modules) || die("Failed to write '\$modulesFile': $!\\n");
}

print "Getting cmd...\\n" if \$verbose;
my (undef, \$cmdFile) = tempfile('testontap_cmd_XXXX', TMPDIR => 1, UNLINK => 1);

$x_liblocs
\$_ = slashify(\$_) foreach (\@liblocs);

my \@cmd =
	(
		'pp',
		\$verbose ? ("--verbose=\$verbose") : (),
		\@liblocs,
		'-a', "\$_argsPodInput;lib/$_argsPodName",
		'-a', "\$argsPodInput;lib/$argsPodName",
		'-a', "\$manualPodInput;lib/$manualPodName",
		'-a', "\$cmdFile;TESTONTAP_CMD_FILE",
		'-a', "\$configFile;TESTONTAP_CONFIG_FILE",
		'-a', "\$modulesFile;TESTONTAP_MODULES_FILE",
		'-a', "\$usernameFile;TESTONTAP_USERNAME_FILE",
		'-a', "\$hostnameFile;TESTONTAP_HOSTNAME_FILE",
		'-a', "\$envFile;TESTONTAP_ENV_FILE",
		'-M', 'Encode::*',
		'-o', \$outfile,
		slashify(File::Spec->rel2abs('$x_input'))
	);

my \@cmdCopy = \@cmd;
\$_ .= "\\n" foreach (\@cmdCopy);
if (\$info)
{
	write_file(\$cmdFile, { binmode => ':raw' }, \@cmdCopy) || die("Failed to write '\$cmdFile': \$!\\n");
}

if (\$verbose)
{
	print "Packing to '\$outfile' using:\\n";
	print "  \$_\\n" foreach (\@cmd);
}
else
{
	print "Packing to '\$outfile'...";
}

if (\$debug)
{
	print "username file     : \$usernameFile\\n";
	print "hostname file     : \$hostnameFile\\n";
	print "config file       : \$configFile\\n";
	print "env file          : \$envFile\\n";
	print "modules file      : \$modulesFile\\n";
	print "cmd file          : \$cmdFile\\n";
	print "Continue? (no) : ";
	my \$ans = <STDIN>;
	exit(1) unless \$ans =~ /^\\s*yes\\s*\$/i;
}

my \$xit = system(\@cmd) >> 8;
die("\\nError during packing: \$xit\\n") if \$xit;
print "done\\n";

exit(0);

###

sub getEnv
{
	my \$env = '';
	\$env .= "\$_ => '\$ENV{\$_}'\\n" foreach (sort(keys(\%ENV)));
	
	return \$env;
}

sub find_modules
{
	my \$ei = ExtUtils::Installed->new(skip_cwd => 1);

	my \$modules = '';
	foreach my \$module (sort(\$ei->modules()))
	{
		my \$ver = \$ei->version(\$module);
		\$modules .= "\$module => \$ver\\n";
	}
		
	return \$modules;
}

sub slashify
{
	my \$s = shift;
	my \$fsep = shift || '$x_fsep';

	my \$dblStart = \$s =~ s#^[\\\\/]{2}##;
	\$s =~ s#[/\\\\]+#\$fsep#g;

	return \$dblStart ? "\$fsep\$fsep\$s" : \$s;
}

sub usage
{
	print <<USAGE;
Usage: \$0
          [--output <file>]
          [--verbose || --no-verbose];
          [--info || --no-info]

Creates a testontap binary with a default name of '$x_output'.
Use '--output' to change.

Use '--verbose' or '--no-verbose' to turn on/off verboseness.
Defaults to verboseness when script was created (currently '$x_verbose').

By default a number of information parts is embedded in the packed file (to be printed
with '--_pp_info'). Use '--no-info' to embed blank data only. 
USAGE
	exit(42);
}
SCRIPT

	write_file($scriptFile, $script) || die("Failed to write '$scriptFile': $!\n");
	
	if (!$IS_WINDOWS)
	{
		my $mode = (stat($scriptFile))[2];
		$mode |= 0100;
		chmod($mode, $scriptFile);
	}
	 
	return $scriptFile;
}

1;
