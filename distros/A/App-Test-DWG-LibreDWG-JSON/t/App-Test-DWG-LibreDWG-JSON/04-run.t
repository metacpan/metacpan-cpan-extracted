use strict;
use warnings;

use App::Test::DWG::LibreDWG::JSON;
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
Usage: $script [-d test_dir] [-h] [-i] [-v level] [--version] dwg_file
	-d test_dir	Test directory (default is directory in system tmp).
	-h		Print help.
	-i		Ignore errors.
	-v level	Verbosity level (default 0, max 9).
	--version	Print version.
	dwg_file	AutoCAD DWG file to test.
END
stderr_is(
	sub {
		App::Test::DWG::LibreDWG::JSON->new->run;
		return;
	},
	$right_ret,
	'Run help.',
);
