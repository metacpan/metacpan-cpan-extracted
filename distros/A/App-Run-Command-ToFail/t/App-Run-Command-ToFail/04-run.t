use strict;
use warnings;

use App::Run::Command::ToFail;
use English;
use File::Object;
use File::Spec::Functions qw(abs2rel);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Test::Output;

# Test.
@ARGV = (
	'-h',
);
my $script = abs2rel(File::Object->new->file('04-run.t')->s);
# XXX Hack for missing abs2rel on Windows.
if ($OSNAME eq 'MSWin32') {
	$script =~ s/\\/\//msg;
}
my $right_ret = <<"END";
Usage: $script [-h] [-l] [-n cycles] [-p preset] [--version]
	-h		Print help.
	-l		List presets.
	-n cycles	Number of cycles (default is 100).
	-p preset	Preset for run (default is perl).
	--version	Print version.
END
stderr_is(
	sub {
		App::Run::Command::ToFail->new->run;
		return;
	},
	$right_ret,
	'Run help.',
);

# Test.
@ARGV = (
	'-n 10',
	File::Object->new->up->dir('data')->file('test_ok.pl')->s,
	10,
);
$right_ret = <<'END';
Everything is ok.
END
stdout_is(
	sub {
		App::Run::Command::ToFail->new->run;
		return;
	},
	$right_ret,
	'Run test, which is successful (10x run).',
);

# Test.
@ARGV = (
	'-n 10',
	File::Object->new->up->dir('data')->file('test_fail.pl')->s,
	10,
	5,
);
$right_ret = <<'END';
Error.
Exited in 5 round with exit code 256.
END
stderr_is(
	sub {
		App::Run::Command::ToFail->new->run;
		return;
	},
	$right_ret,
	'Run test, which is failing (10x run, fail in 5 round).',
);
