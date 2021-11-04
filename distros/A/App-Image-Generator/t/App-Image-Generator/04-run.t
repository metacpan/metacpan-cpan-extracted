use strict;
use warnings;

use App::Image::Generator;
use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Output;

#App::Image::Generator->new->run;

# Test.
@ARGV = (
	'-h',
);
my $right_ret = <<'END';
Usage: t/App-Image-Generator/04-run.t [-h] [-i input_dir] [-s size] [-v]
	[--version] output_file

	-h		Print help.
	-i input_dir	Input directory with images (default value is nothing).
	-s size		Size (default value is 1920x1080).
	-v		Verbose mode.
	--version	Print version.
END
stderr_is(
	sub {
		App::Image::Generator->new->run;
		return;
	},
	$right_ret,
	'Run help.',
);
