use strict;
use warnings;

use App::Stow::Check;
use English;
use File::Object;
use File::Spec::Functions qw(abs2rel);
use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Output;

# Test.
@ARGV = (
	'-h',
);
my $script = abs2rel(File::Object->new->file('04-run.t')->s);
# XXX Hack for missing abs2rel on Windows.
if ($OSNAME eq 'MSWin32') {
	$script =~ s/\\/\//msg;
}
my $right_ret = <<"END";
Usage: $script [-d stow_dir] [-h] [--version] command
	-d stow_dir	Stow directory (default value is '/usr/local/stow').
	-h		Print help.
	--version	Print version.
	command		Command for which is stow dist looking.
END
stderr_is(
	sub {
		App::Stow::Check->new->run;
		return;
	},
	$right_ret,
	'Run help.',
);
