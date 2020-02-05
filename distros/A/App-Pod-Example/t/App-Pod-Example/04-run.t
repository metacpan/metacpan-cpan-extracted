use strict;
use warnings;

use App::Pod::Example;
use English qw(-no_match_vars);
use File::Object;
use IO::CaptureOutput qw(capture);
use Test::More 'tests' => 18;
use Test::NoWarnings;
use Test::Output;
use Test::Warn;

# Modules dir.
my $modules_dir = File::Object->new->up->dir('modules');

# Test.
@ARGV = (
	'-d' => 0,
	'-r',
	$modules_dir->file('Ex1.pm')->s,
);
my $right_ret = <<'END';
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
my ($stderr, $stdout);
capture sub {
	App::Pod::Example->new->run;
	return;
} => \$stdout, \$stderr;
is($stdout, $right_ret, 'Header on example with die().');
like($stderr, qr{^Error\. at .* line 5\.$}, 'Example with die().');

# Test.
@ARGV = (
	'-d' => 1,
	'-r',
	$modules_dir->file('Ex3.pm')->s,
);
($stderr, $stdout) = (undef, undef);
capture sub {
	App::Pod::Example->new->run;
	return;
} => \$stdout, \$stderr;
is($stdout, $right_ret, 'Header on example with Carp::croak().');
like($stderr, qr{^Error\. at .* line 7\.$}, 'Example with Carp::croak().');

# Test.
@ARGV = (
	'-d' => 1,
	'-r',
	$modules_dir->file('Ex4.pm')->s,
);
($stderr, $stdout) = (undef, undef);
capture sub {
	App::Pod::Example->new->run;
	return;
} => \$stdout, \$stderr;
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
