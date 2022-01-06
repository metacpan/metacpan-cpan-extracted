use strict;
use warnings;

use App::CPAN::Get;
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
Usage: $script [-h] [--version] module_name[module_version]
	-h		Print help.
	--version	Print version.
	module_name	Module name. e.g. App::Pod::Example
	module_version	Module version. e.g. \@1.23, ~1.23 etc.
END
stderr_is(
	sub {
		App::CPAN::Get->new->run;
		return;
	},
	$right_ret,
	'Run help.',
);
