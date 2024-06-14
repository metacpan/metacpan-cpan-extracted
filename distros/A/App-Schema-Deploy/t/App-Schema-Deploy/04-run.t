use strict;
use warnings;

use App::Schema::Deploy;
use English;
use File::Object;
use File::Spec::Functions qw(abs2rel);
use File::Temp qw(tempfile);
use Test::More 'tests' => 7;
use Test::NoWarnings;
use Test::Output;
use Test::Warn;

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
unshift @INC, $data->dir('ex1')->s;
require Schema::Foo;
my (undef, $db_file) = tempfile();
@ARGV = (
	'-q',
	'dbi:SQLite:dbname='.$db_file,
	'Schema::Foo',
);
my $ret = App::Schema::Deploy->new->run;
is($ret, 0, 'Deployed SQLite database.');
unlink $db_file;

# Test.
@ARGV = (
	'-h',
);
my $right_ret_stderr = help();
stderr_is(
	sub {
		App::Schema::Deploy->new->run;
		return;
	},
	$right_ret_stderr,
	'Run help.',
);

# Test.
@ARGV = (
	'dbi:SQLite:dbname=fake.db',
);
$right_ret_stderr = help();
stderr_is(
	sub {
		App::Schema::Deploy->new->run;
		return;
	},
	$right_ret_stderr,
	'Run without Schema module.',
);

# Test.
@ARGV = (
	'-x',
);
warning_is(
	sub {
		stderr_is(
			sub {
				App::Schema::Deploy->new->run;
				return;
			},
			$right_ret_stderr,
			'Run help with bad option.',
		);
	},
	"Unknown option: x\n",
	'Warning about unknown option (x).',
);

# Test.
@ARGV = (
	'dbi:SQLite:dbname=fake.db',
	'bad',
);
eval {
	App::Schema::Deploy->new->run;
};
is($EVAL_ERROR, "Cannot load Schema module.\n", 'Run with bad Schema module.');

sub help {
	my $script = abs2rel(File::Object->new->file('04-run.t')->s);
	# XXX Hack for missing abs2rel on Windows.
	if ($OSNAME eq 'MSWin32') {
		$script =~ s/\\/\//msg;
	}
	my $right_ret_stderr = <<"END";
Usage: $script [-d] [-h] [-p password] [-q] [-u user] [-v schema_version] [--version] dsn schema_module
	-d			Drop tables.
	-h			Print help.
	-p password		Database password.
	-q			Quiet mode.
	-u user			Database user.
	-v schema_version	Schema version (default is latest version).
	--version		Print version.
	dsn			Database DSN. e.g. dbi:SQLite:dbname=ex1.db
	schema_module		Name of Schema module.
END

	return $right_ret_stderr;
}
