use strict;
use warnings;

use App::Images::To::DjVu;
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
Usage: $script [-e encoder] [-h] [-o out_file] [-q] [--version] images_list_file
	-e encoder		Encoder (default value is 'c44').
	-h			Print help.
	-o out_file		Output file (default value is 'output.djvu').
	-q			Quiet mode.
	--version		Print version.
	images_list_file	Text file with images list.
END
stderr_is(
	sub {
		App::Images::To::DjVu->new->run;
		return;
	},
	$right_ret,
	'Run help.',
);
