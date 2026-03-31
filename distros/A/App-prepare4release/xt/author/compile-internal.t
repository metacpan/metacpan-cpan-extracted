#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(skip_all done_testing);
use File::Find ();

BEGIN {
	eval {
		require Test::Compile;
		Test::Compile->import('pm_file_ok');
		1;
	} or skip_all 'Test::Compile is required for this author test';
}

# Per-file compile checks (same underlying machinery as Test::Compile::Internal).
my @pm;
File::Find::find(
	{
		wanted => sub {
			return unless -f && /\.pm\z/;
			push @pm, $File::Find::name;
		},
		no_chdir => 1,
	},
	'lib'
);

pm_file_ok($_) for @pm;

done_testing;
