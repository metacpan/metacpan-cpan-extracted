package App::TestOnTap::Postprocess;

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
	my $argv = shift;

	my $self = bless( { xit => undef }, $class);
	$self->__execPostprocess($cmd, $args, $argv) if $cmd;
	
	return $self;
}

sub __execPostprocess
{
	my $self = shift;
	my $cmd = shift;
	my $args = shift;
	my $argv = shift;
	
	my $cwd = getcwd();
	my $suiteRoot = $args->getSuiteRoot(); 
	chdir($suiteRoot) || die("Failed to change directory to '$suiteRoot': $!\n");
	my @cmdcp = (@$cmd, @$argv);
	$_ = "$SHELL_ARG_DELIM$_$SHELL_ARG_DELIM" foreach (@cmdcp);
	my $cmdString = join(' ', @cmdcp);
	my @postproc = qx($cmdString 2>&1);
	my $xit = $? >> 8;
	chdir($cwd) || die("Failed to change directory back to '$cwd': $!\n");
	if ($xit)
	{
		warn("WARNING: Error $xit when running postprocess command: @postproc\n");
	}
	else
	{
		print STDERR @postproc;
	}
	
	$self->{xit} = $xit;
}

sub getExitCode
{
	my $self = shift;

	return $self->{xit};
}

1;
