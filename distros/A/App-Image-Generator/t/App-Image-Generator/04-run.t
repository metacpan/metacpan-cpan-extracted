use strict;
use warnings;

use App::Image::Generator;
use English;
use Error::Pure::Utils qw(clean);
use File::Object;
use File::Spec::Functions qw(abs2rel);
use Test::More 'tests' => 7;
use Test::NoWarnings;
use Test::Output;
use Test::Warn 0.31;

# Test.
@ARGV = (
	'-h',
);
my $right_ret = help();
stderr_is(
	sub {
		App::Image::Generator->new->run;
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
		App::Image::Generator->new->run;
		return;
	},
	$right_ret,
	'Run help (no output file).',
);

# Test.
@ARGV = (
	'-x',
);
$right_ret = help();
stderr_is(
	sub {
		warning_is { App::Image::Generator->new->run; } "Unknown option: x\n",
			'Warning about bad argument';
		return;
	},
	$right_ret,
	'Run help (-x - bad option).',
);

# Test.
@ARGV = (
	'-s 100',
	'output_file.png',
);
eval {
	App::Image::Generator->new->run;
};
is($EVAL_ERROR, "Bad size value.\n", "Bad size value (-s 100).");
clean();

# Test.
@ARGV = (
	'-p bad_pattern',
	'output_file.png',
);
eval {
	App::Image::Generator->new->run;
};
is($EVAL_ERROR, "Bad pattern.\n", "Bad pattern (-p bad_pattern).");
clean();

sub help {
	my $script = abs2rel(File::Object->new->file('04-run.t')->s);
	# XXX Hack for missing abs2rel on Windows.
	if ($OSNAME eq 'MSWin32') {
		$script =~ s/\\/\//msg;
	}
	my $help = <<"END";
Usage: $script [-h] [-i input_dir] [-p pattern] [-s size] [-v]
	[--version] output_file

	-h		Print help.
	-i input_dir	Input directory with images (default value is nothing).
	-p pattern	Pattern (checkerboard).
	-s size		Size (default value is 1920x1080).
	-v		Verbose mode.
	--version	Print version.
END

	return $help;
}
