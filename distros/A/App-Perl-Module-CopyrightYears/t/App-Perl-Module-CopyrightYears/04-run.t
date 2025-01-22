use strict;
use warnings;

use App::Perl::Module::CopyrightYears;
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
		App::Perl::Module::CopyrightYears->new->run;
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
		warning_is { App::Perl::Module::CopyrightYears->new->run; } "Unknown option: x\n",
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
Usage: $script [-d] [-h] [-s section(s)] [-y last_year] [--version]
	-d		Debug mode.
	-h		Print help.
	-s section(s)	Section(s) to look (default is LICENSE AND COPYRIGHT)
	-y last_year	Last year (default value is actual year)
	--version	Print version.
END

	return $help;
}
