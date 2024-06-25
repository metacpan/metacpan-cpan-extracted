use strict;
use warnings;

use App::Run::Command::ToFail;
use English;
use File::Object;
use File::Spec::Functions qw(abs2rel);
use File::Temp qw(tempfile);
use Test::More 'tests' => 9;
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
		App::Run::Command::ToFail->new->run;
		return;
	},
	$right_ret,
	'Run help.',
);

# Test.
@ARGV = (
	'-x',
);
$right_ret = help();
stderr_is(
	sub {
		warning_is { App::Run::Command::ToFail->new->run; } "Unknown option: x\n",
			'Warning about bad argument';
		return;
	},
	$right_ret,
	'Run help (-x - bad option).',
);

# Test.
@ARGV = (
	'-l',
);
$right_ret = <<'END';
blank: 
perl: perl %s
strace_perl: strace -ostrace.log -esignal,write perl -Ilib %s
END
stdout_is(
	sub {
		App::Run::Command::ToFail->new->run;
		return;
	},
	$right_ret,
	'List presets.',
);

# Test.
@ARGV = (
	'-p',
	'bad',
);
$right_ret = <<'END';
Bad preset. Possible values are 'blank', 'perl', 'strace_perl'.
END
stderr_is(
	sub {
		App::Run::Command::ToFail->new->run;
		return;
	},
	$right_ret,
	'Bad preset (bad).',
);

# Test.
@ARGV = (
	'-p',
	'perl',
);
$right_ret = <<'END';
Wrong number of arguments (need 1 for command 'perl %s').
END
stderr_is(
	sub {
		App::Run::Command::ToFail->new->run;
		return;
	},
	$right_ret,
	'Bad number of arguments (no arguments).',
);

# Test.
my (undef, $temp_file) = tempfile();
@ARGV = (
	'-n',
	10,
	'-p',
	'blank',
	$EXECUTABLE_NAME.' '.File::Object->new->up->dir('data')->file('test_ok.pl')->s.' 10 '.$temp_file,
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
unlink $temp_file;

# Test.
(undef, $temp_file) = tempfile();
@ARGV = (
	'-n',
	10,
	'-p',
	'blank',
	$EXECUTABLE_NAME.' '.File::Object->new->up->dir('data')->file('test_fail.pl')->s.' 10 5 '.$temp_file,
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
unlink $temp_file;

sub help {
	my $script = abs2rel(File::Object->new->file('04-run.t')->s);
	# XXX Hack for missing abs2rel on Windows.
	if ($OSNAME eq 'MSWin32') {
		$script =~ s/\\/\//msg;
	}
	my $help = <<"END";
Usage: $script [-h] [-l] [-n cycles] [-p preset] [--version]
	-h		Print help.
	-l		List presets.
	-n cycles	Number of cycles (default is 100).
	-p preset	Preset for run (default is perl).
	--version	Print version.
END

	return $help;
}
