use strict;
use warnings;

use App::Perl::Module::Examples;
use Cwd qw(getcwd);
use English;
use Error::Pure qw(err);
use File::Copy::Recursive qw(dircopy);
use File::Temp qw(tempdir);
use File::Object;
use File::Spec::Functions qw(abs2rel catdir catfile);
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 13;
use Test::NoWarnings;
use Test::Output;
use Test::Warn 0.31;

# Data directory.
my $data_dir = File::Object->new->up->dir('data')->s;

# Test.
@ARGV = (
	'-h',
);
my $right_ret = help();
stderr_is(
	sub {
		App::Perl::Module::Examples->new->run;
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
		warning_is { App::Perl::Module::Examples->new->run; } "Unknown option: x\n",
			'Warning about bad argument';
		return;
	},
	$right_ret,
	'Run help (-x - bad option).',
);

# Test.
@ARGV = (
	'one',
	'two',
);
$right_ret = help();
stderr_is(
	sub {
		App::Perl::Module::Examples->new->run;
		return;
	},
	$right_ret,
	'Run help (too many arguments).',
);

# Test.
my $temp_dir = tempdir(CLEANUP => 1);
dircopy(catdir($data_dir, 'example1'), $temp_dir)
	or err 'Cannot copy example1 data directory.';
mkdir catfile($temp_dir, 'examples');
@ARGV = (
	'-d',
	$temp_dir,
);
$right_ret = <<'END';
Found Perl modules:
- Ex.pm
END
stdout_is(
	sub {
		App::Perl::Module::Examples->new->run;
	},
	$right_ret,
	'Run on working directory in debug.',
);
$right_ret = <<'END';
#!/usr/bin/env perl

use strict;
use warnings;

# Print.
print "Foo.\n";
END
chomp $right_ret;
is(
	slurp(catfile($temp_dir, 'examples', 'working_dir.pl')),
	$right_ret,
	'Generate example in working directory.',
);

# Test.
my $cwd = getcwd;
my $default_dir = tempdir(CLEANUP => 1);
dircopy(catdir($data_dir, 'example2'), $default_dir)
	or err 'Cannot copy example2 data directory.';
chdir $default_dir or err "Cannot chdir to '$default_dir'.";
@ARGV = ();
is(App::Perl::Module::Examples->new->run, 0, 'Run on default working directory.');
$right_ret = <<'END';
#!/usr/bin/env perl

use strict;
use warnings;

# Print.
print "Default.\n";
END
chomp $right_ret;
is(
	slurp(catfile('examples', 'ex1.pl')),
	$right_ret,
	'Generate example in default working directory.',
);
$right_ret = <<'END';
#!/usr/bin/env perl

use strict;
use warnings;

# Print.
print "Nested.\n";
END
chomp $right_ret;
is(
	slurp(catfile('examples', 'nested.pl')),
	$right_ret,
	'Generate example from module in subdirectory.',
);
chdir $cwd or err "Cannot chdir to '$cwd'.";

# Test.
my $examples_dir = tempdir(CLEANUP => 1);
dircopy(catdir($data_dir, 'example3'), $examples_dir)
	or err 'Cannot copy example3 data directory.';
@ARGV = (
	$examples_dir,
);
is(App::Perl::Module::Examples->new->run, 0, 'Run with EXAMPLES section.');
$right_ret = <<'END';
#!/usr/bin/env perl

use strict;
use warnings;

# Print.
print "First.\n";
END
chomp $right_ret;
is(
	slurp(catfile($examples_dir, 'examples', 'first.pl')),
	$right_ret,
	'Generate EXAMPLE1 from EXAMPLES.',
);
$right_ret = <<'END';
#!/usr/bin/env perl

use strict;
use warnings;

# Print.
print "Second.\n";
END
chomp $right_ret;
is(
	slurp(catfile($examples_dir, 'examples', 'second.pl')),
	$right_ret,
	'Generate EXAMPLE2 from EXAMPLES.',
);

sub help {
	my $script = abs2rel(__FILE__);
	if ($OSNAME eq 'MSWin32') {
		$script =~ s/\\/\//msg;
	}
	my $help = <<"END";
Usage: $script [-d] [-h] [--version] [working_dir]
	-d		Debug mode.
	-h		Print help.
	--version	Print version.
	[working_dir]	Working directory (default is actual).
END

	return $help;
}
