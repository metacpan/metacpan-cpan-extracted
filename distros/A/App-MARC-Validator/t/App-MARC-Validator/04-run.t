use strict;
use warnings;

use App::MARC::Validator;
use English;
use File::Object;
use File::Spec::Functions qw(abs2rel);
use Test::More 'tests' => 6;
use Test::NoWarnings;
use Test::Output;
use Test::Warn 0.31;

# Test.
@ARGV = (
	'-l',
);
my $right_ret = "List of plugins:\n- MARC::Validator";
stdout_like(
	sub {
		App::MARC::Validator->new->run;
		return;
	},
	qr{^$right_ret},
	'List plugins (-l).',
);

# Test.
@ARGV = (
	'-h',
);
$right_ret = help();
stderr_is(
	sub {
		App::MARC::Validator->new->run;
		return;
	},
	$right_ret,
	'Run help (-h).',
);

# Test.
@ARGV = ();
$right_ret = help();
stderr_is(
	sub {
		App::MARC::Validator->new->run;
		return;
	},
	$right_ret,
	'Run help (no arguments).',
);

# Test.
@ARGV = (
	'-x',
);
$right_ret = help();
stderr_is(
	sub {
		warning_is { App::MARC::Validator->new->run; } "Unknown option: x\n",
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
Usage: $script [-d] [-h] [-i id] [-l] [-o output_file] [-p] [-v] [--version] marc_xml_file..
	-d		Debug mode.
	-h		Print help.
	-i id		Record identifier (default value is 001).
	-l		List of plugins.
	-o output_file	Output file (default is STDOUT).
	-p		Pretty print JSON output.
	-v		Verbose mode.
	--version	Print version.
	marc_xml_file..	MARC XML file(s).
END

	return $help;
}
