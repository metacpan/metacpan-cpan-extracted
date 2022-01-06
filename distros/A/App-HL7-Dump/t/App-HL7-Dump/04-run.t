use strict;
use warnings;

use App::HL7::Dump;
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
Usage: $script [-c] [-h] [--version] hl7_file
	-c		Color mode.
	-h		Print help.
	--version	Print version.
END
stderr_is(
	sub {
		App::HL7::Dump->new->run;
		return;
	},
	$right_ret,
	'Run help.',
);
