package TestUtils;

use strict;
use warnings;

use App::TestOnTap;

use FindBin qw($Bin $Script);

use Capture::Tiny qw(:all);
use File::Basename;
use File::Find;
use Test::More;

sub xeqsuite
{
	my @argv = @_;
	
	my $suitename = suitename_from_script();
	
	my ($stdout, $stderr, $ret) = capture
							{	
								my $ret = -1;
								eval
								{
									$ret = App::TestOnTap::main(@argv, "$Bin/tsuites/$suitename");
								};
								if ($@)
								{
									print STDERR $@;
								}
								return $ret;
							};

	my $split_stderr = [split(/\n/, $stderr)];
	for my $line (0 .. (scalar(@$split_stderr) - 1))
	{
		note("STDERR $line : $split_stderr->[$line]");
	}

	my $split_stdout = [split(/\n/, $stdout)];
	for my $line (0 .. (scalar(@$split_stdout) - 1))
	{
		note("STDOUT $line : $split_stdout->[$line]");
	}
		
	return ($ret, $split_stdout, $split_stderr);
}

sub suitename_from_script
{
	my $bn = basename($Script);
	die("Unexpected script basename: '$bn'") unless $bn =~ /^\d\d-(.+)\.t$/;
	return $1;
}

sub get_tree
{
	my $root = shift;
	
	my @tree;
	find
		(
			{
				wanted => sub
							{
								my $ffn = $File::Find::name;
								$ffn .= '/' if -d $ffn; 
								$ffn =~ s#^\Q$root\E[\\/]##;
								push(@tree, $ffn) if $ffn;
							},
				no_chdir => 1
			},
			$root
		);

	return [ sort(@tree) ];	
}

1;