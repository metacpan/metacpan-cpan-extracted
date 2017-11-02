package App::TestOnTap::PackInfo;

use App::TestOnTap::Util qw(slashify $IS_WINDOWS $IS_PACKED $SHELL_ARG_DELIM);

use Config qw(myconfig);
use ExtUtils::Installed;
use File::Basename;
use File::Slurp qw(write_file);
use File::Spec;
use File::Temp qw(tempfile);
use FindBin qw($RealBin $Script);
use PAR;
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
	
	die("Only one of --_pp, --_info, --_info_cmd, --_info_config, --_info_modules allowed\n") if grep(/^_(pp|info)$/, keys(%$opts)) > 1;
	if    ($opts->{'_pp'})           { _pp($opts, $version, $_argsPodName, $_argsPodInput, $argsPodName, $argsPodInput, $manualPodName, $manualPodInput); }
	elsif ($opts->{'_info'})         { _info($opts, $_argsPodName, $_argsPodInput, $argsPodName, $argsPodInput, $manualPodName, $manualPodInput); }
	elsif ($opts->{'_info_cmd'})     { _info_cmd($opts, $_argsPodName, $_argsPodInput, $argsPodName, $argsPodInput, $manualPodName, $manualPodInput); }
	elsif ($opts->{'_info_config'})  { _info_config(); }
	elsif ($opts->{'_info_modules'}) { _info_modules(); }
	else { die("INTERNAL ERROR"); }
		
	exit(0);
}

sub _pp
{
	my $opts = shift;
	my $version = shift;
	my $_argsPodName = shift;
	my $_argsPodInput = shift;
	my $argsPodName = shift;
	my $argsPodInput = shift;
	my $manualPodName = shift;
	my $manualPodInput = shift;

	die("Sorry, you're already running a binary/packed instance\n") if $IS_PACKED;
	
	eval "require PAR::Packer";
	warn("Sorry, it appears PAR::Packer is not installed/working!\n") if $@;

	my $output = __construct_output($version);
	die("The output file exists: '$output'\n") if -e $output;

	my (undef, $configFile) = tempfile('testontap_config_XXXX', TMPDIR => 1, UNLINK => 1);
	write_file($configFile, __find_config()) || die("Failed to write '$configFile': $!\n");
	 
	my (undef, $modulesFile) = tempfile('testontap_modules_XXXX', TMPDIR => 1, UNLINK => 1);
	write_file($modulesFile, __find_modules()) || die("Failed to write '$modulesFile': $!\n");

	my (undef, $cmdFile) = tempfile('testontap_cmd_XXXX', TMPDIR => 1, UNLINK => 1);
	my @cmd = __find_cmd($opts, $_argsPodName, $_argsPodInput, $argsPodName, $argsPodInput, $manualPodName, $manualPodInput, $output, $cmdFile, $configFile, $modulesFile);
	my @cmdCopy = @cmd;
	$_ .= "\n" foreach (@cmdCopy);
	write_file($cmdFile, { binmode => ':raw' }, @cmdCopy) || die("Failed to write '$cmdFile': $!\n");
	
	if ($opts->{verbose})
	{
		print "Packing to '$output' using:\n";
		print "  $_\n" foreach (@cmd);
	}
	else
	{
		print "Packing to '$output'...";
	}

	my $xit = system(@cmd) >> 8;
	die("\nError during packing: $xit\n") if $xit;
	print "done\n";
}

sub _info
{
	my $opts = shift;
	my $_argsPodName = shift;
	my $_argsPodInput = shift;
	my $argsPodName = shift;
	my $argsPodInput = shift;
	my $manualPodName = shift;
	my $manualPodInput = shift;

	my $isPacked = $IS_PACKED ? 'Yes' : 'No';
	print "$0 (packed: $isPacked)\n";
	
	print "### CMD BEGIN\n";
	_info_cmd($opts, $_argsPodName, $_argsPodInput, $argsPodName, $argsPodInput, $manualPodName, $manualPodInput);
	print "### CMD END\n";

	print "### CONFIG BEGIN\n";
	_info_config();
	print "### CONFIG END\n";

	print "### MODULES BEGIN\n";
	_info_modules();
	print "### MODULES END\n";
}

sub _info_cmd
{
	my $opts = shift;
	my $_argsPodName = shift;
	my $_argsPodInput = shift;
	my $argsPodName = shift;
	my $argsPodInput = shift;
	my $manualPodName = shift;
	my $manualPodInput = shift;

	print __cmd2string(__find_cmd($opts, $_argsPodName, $_argsPodInput, $argsPodName, $argsPodInput, $manualPodName, $manualPodInput)); 	
}

sub _info_config
{
	print __find_config();
}

sub _info_modules
{
	print __find_modules();
}

###

sub __find_cmd
{
	my $opts = shift;
	my $_argsPodName = shift;
	my $_argsPodInput = shift;
	my $argsPodName = shift;
	my $argsPodInput = shift;
	my $manualPodName = shift;
	my $manualPodInput = shift;
	my $outputFile = shift || 'TESTONTAP_OUTPUT_FILE';
	my $cmdFile = shift || 'TESTONTAP_CMD_FILE';
	my $configFile = shift || 'TESTONTAP_CONFIG_FILE';
	my $modulesFile = shift || 'TESTONTAP_MODULES_FILE';
	
	my @cmd;

	if ($IS_PACKED)
	{
		@cmd = split(/\n/, PAR::read_file("TESTONTAP_CMD_FILE")); 
	}
	else
	{
		my @liblocs = map { ($_ ne '.' && !ref($_)) ? ('-I', slashify(File::Spec->rel2abs($_))) : () } @INC;
		@cmd =
			(
				'pp',
				$opts->{verbose} ? ("--verbose=$opts->{verbose}") : (),
				@liblocs,
				'-a', "$_argsPodInput;lib/$_argsPodName",
				'-a', "$argsPodInput;lib/$argsPodName",
				'-a', "$manualPodInput;lib/$manualPodName",
				'-a', "$cmdFile;TESTONTAP_CMD_FILE",
				'-a', "$configFile;TESTONTAP_CONFIG_FILE",
				'-a', "$modulesFile;TESTONTAP_MODULES_FILE",
				'-M', 'Encode::*',
				'-o', $outputFile,
				slashify("$RealBin/$Script")
			);
	}
	
	return @cmd;
}

sub __find_config
{
	my $config;

	if ($IS_PACKED)
	{
		$config = PAR::read_file("TESTONTAP_CONFIG_FILE");
	}
	else
	{
		$config = myconfig();
	}

	return $config;
}

sub __find_modules
{
	my $modules;

	if ($IS_PACKED)
	{
		$modules = PAR::read_file("TESTONTAP_MODULES_FILE");
	}
	else
	{
		my $ei = ExtUtils::Installed->new(skip_cwd => 1);
	
		$modules = '';
		foreach my $module (sort($ei->modules()))
		{
			my $ver = $ei->version($module);
			$modules .= "$module => $ver\n";
		}
	}
		
	return $modules;
}

sub __construct_output
{
	my $version = shift;
	
	my $os = $IS_WINDOWS ? 'windows' : $^O;
	my $arch = (POSIX::uname())[4];
	my $exeSuffix = $IS_WINDOWS ? '.exe' : '';
	my $bnScript = basename($Script);
	
	return "$bnScript-$version-$os-$arch$exeSuffix";
}

sub __cmd2string
{
	my $cmd = '';
	$cmd .= "$SHELL_ARG_DELIM$_$SHELL_ARG_DELIM " foreach (@_);
	chop($cmd);
	
	return $cmd;
}

1;
