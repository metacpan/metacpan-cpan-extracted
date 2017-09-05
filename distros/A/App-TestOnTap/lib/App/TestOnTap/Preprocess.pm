package App::TestOnTap::Preprocess;

use App::TestOnTap::Util qw($SHELL_ARG_DELIM);

use POSIX;

use strict;
use warnings;

# CTOR
#
sub new
{
	my $class = shift;
	my $cmd = shift;
	my $args = shift;
	my $env = shift;
	my $argv = shift;

	my $self = bless( { env => $env, argv => $argv }, $class);
	$self->__execPreprocess($cmd, $args) if $cmd;
	
	return $self;
}

sub getEnv
{
	my $self = shift;
	
	return $self->{env};
}

sub getArgv
{
	my $self = shift;

	return $self->{argv};
}

sub __execPreprocess
{
	my $self = shift;
	my $cmd = shift;
	my $args = shift;
	
	my $cwd = getcwd();
	my $suiteRoot = $args->getSuiteRoot(); 
	chdir($suiteRoot) || die("Failed to change directory to '$suiteRoot': $!\n");
	my @cmdcp = (@$cmd, @{$self->getArgv()});
	$_ = "$SHELL_ARG_DELIM$_$SHELL_ARG_DELIM" foreach (@cmdcp);
	my $cmdString = join(' ', @cmdcp);
	my @preproc = qx($cmdString);
	my $xit = $? >> 8;
	chdir($cwd) || die("Failed to change directory back to '$cwd': $!\n");
	die("Error $xit when running preprocess command: @preproc\n") if $xit;

	my %types =
		(
			ENV => sub
					{
						$self->__parseEnvLines(@_)
					},
			ARGV => sub
					{
						$self->__parseArgvLines(@_)
					}
		);
	chomp(@preproc);	
	while (my $line = shift(@preproc))
	{
		if ($line =~ /^\s*#\s*BEGIN\s+([^\s]+)\s*$/ && exists($types{$1}))
		{
			$types{$1}->($1, \@preproc);
		}
		else
		{
			warn("WARNING: Unexpected line during preprocessing: '$line'\n");
		}
	}	
}

sub __parseEnvLines
{
	my $self = shift;
	my $type = shift;
	my $preproc = shift;

	my %env;
	while (my $line = shift(@$preproc))
	{
		last if $line =~ /^\s*#\s*END\s+\Q$type\E\s*$/;
		die("Invalid $type line during preprocessing: '$line'\n") unless ($line =~ /^([^=]+)=(.*)/);
		$env{$1} = $2 || '';
	}
	
	$self->{env} = \%env;
}

sub __parseArgvLines
{
	my $self = shift;
	my $type = shift;
	my $preproc = shift;

	my @argv;
	while (my $line = shift(@$preproc))
	{
		last if $line =~ /^\s*#\s*END\s+\Q$type\E\s*$/;
		push(@argv, $line);
	}
	
	$self->{argv} = \@argv;
}

1;
