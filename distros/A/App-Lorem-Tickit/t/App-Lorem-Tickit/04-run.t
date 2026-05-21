use strict;
use warnings;

use App::Lorem::Tickit;
use English;
use File::Spec::Functions qw(abs2rel);
use Test::More 'tests' => 4;
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
		App::Lorem::Tickit->new->run;
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
		warning_is { App::Lorem::Tickit->new->run; } "Unknown option: x\n",
			'Warning about bad argument';
		return;
	},
	$right_ret,
	'Run help (-x - bad option).',
);

sub help {
	my $script = abs2rel(__FILE__);
	if ($OSNAME eq 'MSWin32') {
		$script =~ s/\\/\//msg;
	}
	my $help = <<"END";
Usage: $script [-h] [--version]
	-h		Print help.
	--version	Print version.
END

	return $help;
}
