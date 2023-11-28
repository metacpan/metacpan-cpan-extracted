#! perl

use strict;
use warnings;

use ExtUtils::Helpers 'make_executable';
use File::Basename 'basename';
use File::Copy 'copy';

use lib 'lib';
use CPAN::Static::Install ':all';

my %opts = opts_from_args_list(@ARGV);
if (basename($0) eq 'Build.PL') {
	configure(%opts, static_version => supports_static_install);
	copy('Build.PL', 'Build');
	make_executable('Build');
} else {
	my $command = shift || 'build';
	if ($command eq 'build') {
		build(%opts);
	} elsif ($command eq 'test') {
		test(%opts);
	} elsif ($command eq 'install') {
		install(%opts);
	} else {
		die "Unknown subcommand $command";
	}
}
