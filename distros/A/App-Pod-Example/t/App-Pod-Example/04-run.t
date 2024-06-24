use strict;
use warnings;

use App::Pod::Example;
use Capture::Tiny qw(capture);
use English;
use Error::Pure::Utils qw(clean);
use File::Object;
use File::Spec::Functions qw(abs2rel);
use Test::More 'tests' => 23;
use Test::NoWarnings;
use Test::Output;
use Test::Warn;

# Modules dir.
my $modules_dir = File::Object->new->up->dir('modules');

# Test.
@ARGV = (
	'-h',
);
my $right_ret = help();
stderr_is(
	sub {
		App::Pod::Example->new->run;
		return;
	},
	$right_ret,
	'Run help (-h).',
);

# Test.
@ARGV = ();
$right_ret = help();
stderr_is(
	sub {
		App::Pod::Example->new->run;
		return;
	},
	$right_ret,
	'Run help (no arguments).',
);

# Test.
@ARGV = (
	'-x',
);
$right_ret = help();
stderr_is(
	sub {
		warning_is { App::Pod::Example->new->run; } "Unknown option: x\n",
			'Warning about bad argument';
		return;
	},
	$right_ret,
	'Run help (-x - bad option).',
);

# Test.
@ARGV = (
	'Foo',
);
eval {
       App::Pod::Example->new->run;
};
is($EVAL_ERROR, "Cannot process any action (-p or -r options).\n",
	'No action.');
clean();

# Test.
@ARGV = (
	'-d' => 0,
	'-r',
	$modules_dir->file('Ex1.pm')->s,
);
$right_ret = <<'END';
Foo.
END
stdout_is(
	sub {
		App::Pod::Example->new->run;
		return;
	},
	$right_ret,
	'Example with simple run().',
);

# Test.
@ARGV = (
	'-d' => 1,
	'-r',
	$modules_dir->file('Ex1.pm')->s,
);
$right_ret = <<'END';
#-------------------------------------------------------------------------------
# Example output
#-------------------------------------------------------------------------------
Foo.
END
stdout_is(
	sub {
		App::Pod::Example->new->run;
		return;
	},
	$right_ret,
	'Example with simple run().',
);

# Test.
@ARGV = (
	'-d' => 1,
	'-r',
	$modules_dir->file('Ex2.pm')->s,
);
$right_ret = <<'END';
#-------------------------------------------------------------------------------
# Example output
#-------------------------------------------------------------------------------
END
my ($stdout, $stderr) = capture {
	App::Pod::Example->new->run;
};
is($stdout, $right_ret, 'Header on example with die().');
like($stderr, qr{^Error\. at .* line 5\.$}, 'Example with die().');

# Test.
@ARGV = (
	'-d' => 1,
	'-r',
	$modules_dir->file('Ex3.pm')->s,
);
($stdout, $stderr) = capture {
	App::Pod::Example->new->run;
};
is($stdout, $right_ret, 'Header on example with Carp::croak().');
like($stderr, qr{^Error\. at .* line 7\.$}, 'Example with Carp::croak().');

# Test.
@ARGV = (
	'-d' => 1,
	'-r',
	$modules_dir->file('Ex4.pm')->s,
);
($stdout, $stderr) = capture {
	App::Pod::Example->new->run;
};
is($stdout, $right_ret, 'Header on example with Error::Pure::Die::err().');
like($stderr, qr{^Error\. at .* line 7\.$},
	'Example with Error::Pure::Die::err().');

# Test.
@ARGV = (
	'-d' => 1,
	'-r',
	$modules_dir->file('Ex5.pm')->s,
);
$right_ret = <<'END';
#-------------------------------------------------------------------------------
# Example output
#-------------------------------------------------------------------------------
Foo.
END
stdout_is(
	sub {
		App::Pod::Example->new->run;
		return;
	},
	$right_ret,
	'Example as EXAMPLE1.',
);

# Test.
@ARGV = (
	'-d' => 1,
	'-n' => 1,
	'-r',
	$modules_dir->file('Ex5.pm')->s,
);
$right_ret = <<'END';
#-------------------------------------------------------------------------------
# Example output
#-------------------------------------------------------------------------------
Foo.
END
stdout_is(
	sub {
		App::Pod::Example->new->run;
		return;
	},
	$right_ret,
	'Example as EXAMPLE1 with explicit example number.',
);

# Test.
@ARGV = (
	'-d' => 1,
	'-n' => 2,
	'-r',
	$modules_dir->file('Ex5.pm')->s,
);
$right_ret = <<'END';
#-------------------------------------------------------------------------------
# Example output
#-------------------------------------------------------------------------------
Bar.
END
stdout_is(
	sub {
		App::Pod::Example->new->run;
		return;
	},
	$right_ret,
	'Example EXAMPLE2 with explicit example number.',
);

# Test.
@ARGV = (
	'-d' => 1,
	'-r',
	'-s' => 'EXAMPLE',
	$modules_dir->file('Ex6.pm')->s,
);
$right_ret = <<'END';
#-------------------------------------------------------------------------------
# Example output
#-------------------------------------------------------------------------------
Argument #0: 
Argument #1: 
END
stdout_is(
	sub {
		App::Pod::Example->new->run;
		return;
	},
	$right_ret,
	'Example Ex6 EXAMPLE with arguments - bad run() calling.',
);

# Test.
@ARGV = (
	'-d' => 1,
	'-r',
	'-s' => 'EXAMPLE',
	$modules_dir->file('Ex6.pm')->s,
	'Foo', 'Bar',
);
$right_ret = <<'END';
#-------------------------------------------------------------------------------
# Example output
#-------------------------------------------------------------------------------
Argument #0: Foo
Argument #1: Bar
END
stdout_is(
	sub {
		App::Pod::Example->new->run;
		return;
	},
	$right_ret,
	'Example Ex6 EXAMPLE with arguments - two arguments.',
);

# Test.
@ARGV = (
	'-d' => 1,
	'-p',
	$modules_dir->file('Ex1.pm')->s,
);
$right_ret = <<'END';
#-------------------------------------------------------------------------------
# Example source
#-------------------------------------------------------------------------------
use strict;
use warnings;

# Print foo.
print "Foo.\n";
END
stdout_is(
	sub {
		App::Pod::Example->new->run;
		return;
	},
	$right_ret,
	'Example with simple print().',
);

# Test.
@ARGV = (
	'-d' => 0,
	'-p',
	$modules_dir->file('Ex1.pm')->s,
);
$right_ret = <<'END';
use strict;
use warnings;

# Print foo.
print "Foo.\n";
END
stdout_is(
	sub {
		App::Pod::Example->new->run;
		return;
	},
	$right_ret,
	'Example with simple print() without debug.',
);

# Test.
@ARGV = (
	'-d' => 1,
	'-n' => 100,
	'-r',
	$modules_dir->file('Ex1.pm')->s,
);
$right_ret = <<'END';
No code.
END
stdout_is(
	sub {
		App::Pod::Example->new->run;
		return;
	},
	$right_ret,
	'No code.',
);

# Test.
@ARGV = (
	'-d' => 0,
	'-e',
	'-p',
	$modules_dir->file('Ex1.pm')->s,
);
$right_ret = <<'END';
1: use strict;
2: use warnings;
3: 
4: # Print foo.
5: print "Foo.\n";
END
stdout_is(
	sub {
		App::Pod::Example->new->run;
		return;
	},
	$right_ret,
	'Example with simple print() without debug and with '.
		'enumerating lines.',
);

sub help {
	my $script = abs2rel(File::Object->new->file('04-run.t')->s);
	# XXX Hack for missing abs2rel on Windows.
	if ($OSNAME eq 'MSWin32') {
		$script =~ s/\\/\//msg;
	}
	my $help = <<"END";
Usage: $script [-d flag] [-e] [-h] [-n number] [-p] [-r]
	[-s section] [--version] pod_file_or_module [argument ..]

	-d flag		Turn debug (0/1) (default is 1).
	-e		Enumerate lines. Only for print mode.
	-h		Help.
	-n number	Number of example (default is nothing).
	-p		Print example.
	-r		Run example.
	-s section	Use section (default EXAMPLE).
	--version	Print version.
END

	return $help;
}
