use strict;
use warnings;

use English;
use File::Object;
use File::Spec::Functions qw(abs2rel);
use App::PYX::Optimization;
use Test::More 'tests' => 7;
use Test::NoWarnings;
use Test::Output;
use Test::Warn;

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Common.
my $script = abs2rel(File::Object->new->file('04-run.t')->s);
# XXX Hack for missing abs2rel on Windows.
if ($OSNAME eq 'MSWin32') {
	$script =~ s/\\/\//msg;
}
my $help = <<"END";
Usage: $script [-h] [--version] [filename] [-]
	-h		Print help.
	--version	Print version.
	filename	Process on filename.
	-		Process on stdin.
END

# Test.
@ARGV = (
	'-h',
);
stderr_is(
	sub {
		App::PYX::Optimization->new->run;
		return;
	},
	$help,
	'Run help.',
);

# Test.
@ARGV = ();
stderr_is(
	sub {
		App::PYX::Optimization->new->run;
		return;
	},
	$help,
	'No option.',
);

# Test.
@ARGV = (
	'-x',
);
stderr_is(
	sub {
		warning_is { App::PYX::Optimization->new->run } "Unknown option: x\n",
			'Warning about bad argument';
		return;
	},
	$help,
	'Bad argument.',
);

# Test.
@ARGV = (
	$data_dir->file('element.pyx')->s,
);
my $right_ret = <<'END';
_comment
(element
Apar val
-text
)element
END
stdout_is(
	sub {
		App::PYX::Optimization->new->run;
		return;
	},
	$right_ret,
	'Optimize PYX file.',
);

# Test.
@ARGV = (
	'-'
);
local *STDIN;
open STDIN, '<', $data_dir->file('element.pyx')->s;
$right_ret = <<'END';
_comment
(element
Apar val
-text
)element
END
stdout_is(
	sub {
		App::PYX::Optimization->new->run;
		return;
	},
	$right_ret,
	'Optimize PYX stdin.',
);
close STDIN;
