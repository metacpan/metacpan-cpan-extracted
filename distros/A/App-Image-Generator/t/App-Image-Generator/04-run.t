use strict;
use warnings;

use App::Image::Generator;
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
my $right_ret = <<"END";
Usage: $script [-h] [-i input_dir] [-s size] [-v]
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
