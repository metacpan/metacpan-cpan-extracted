use strict;
use warnings;

use App::Tickit::Hello;
use English;
use File::Object;
use File::Spec::Functions qw(abs2rel);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Test::Output;
use Test::Warn;

# Test.
@ARGV = (
	'-h',
);
my $right_ret = help();
stderr_is(
	sub {
		App::Tickit::Hello->new->run;
		return;
	},
	$right_ret,
	'Run help (-h).',
);

# Test.
@ARGV = (
	'-x',
);
$right_ret = help();
stderr_is(
	sub {
		warning_is { App::Tickit::Hello->new->run; } "Unknown option: x\n",
			'Warning about bad argument';
		return;
	},
	$right_ret,
	'Run help (-x - bad option).',
);

sub help {
	my $script = abs2rel(File::Object->new->file('04-run.t')->s);
	# XXX Hack for missing abs2rel on Windows.
	if ($OSNAME eq 'MSWin32') {
		$script =~ s/\\/\//msg;
	}
	my $help = <<"END";
Usage: $script [-a horiz_align] [-b bg_color] [-f fg_color] [-h] [-v vert_align] [--version]
	-a horiz_align	Horizontal align (left, center - default, right).
	-b bg_color	Background color (default is black).
	-f fg_color	Foreground color (default is green).
	-h		Print help.
	-v vert_align	Vertical align (top, middle - default, bottom).
	--version	Print version.
END

	return $help;
}
