use strict;
use warnings;

use App::CPAN::Search;
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
Usage: $script [-h] [--version] module_prefix
	-h		Print help.
	--version	Print version.
	module_prefix	Module prefix. e.g. Module::Install
END
stderr_is(
	sub {
		App::CPAN::Search->new->run;
		return;
	},
	$right_ret,
	'Run help.',
);
