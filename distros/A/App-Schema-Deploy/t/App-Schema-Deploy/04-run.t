use strict;
use warnings;

use App::Schema::Deploy;
use English;
use File::Object;
use File::Spec::Functions qw(abs2rel);
use Test::More 'tests' => 6;
use Test::NoWarnings;
use Test::Output;
use Test::Warn;

# Test.
@ARGV = (
	'-h',
);
my $script = abs2rel(File::Object->new->file('04-run.t')->s);
# XXX Hack for missing abs2rel on Windows.
if ($OSNAME eq 'MSWin32') {
	$script =~ s/\\/\//msg;
}
my $right_ret_stderr = <<"END";
Usage: $script [-h] [-p password] [-u user] [-v schema_version] [--version] dsn schema_module
	-h			Print help.
	-p password		Database password.
	-u user			Database user.
	-v schema_version	Schema version (default is latest version).
	--version		Print version.
	dsn			Database DSN. e.g. dbi:SQLite:dbname=ex1.db
	schema_module		Name of Schema module.
END
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
