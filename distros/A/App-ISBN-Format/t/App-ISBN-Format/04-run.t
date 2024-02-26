use strict;
use warnings;

use App::ISBN::Format;
use English;
use File::Object;
use File::Spec::Functions qw(abs2rel);
use Test::More 'tests' => 6;
use Test::NoWarnings;
use Test::Output;

# Common.
my $script = abs2rel(File::Object->new->file('04-run.t')->s);
# XXX Hack for missing abs2rel on Windows.
if ($OSNAME eq 'MSWin32') {
	$script =~ s/\\/\//msg;
}
my $help = <<"END";
Usage: $script [-h] [--version] isbn_string
	-h		Print help.
	--version	Print version.
	isbn_string	ISBN string.
END
my $data = File::Object->new->up->dir('data');

# Test.
@ARGV = (
	'-h',
);
stderr_is(
	sub {
		App::ISBN::Format->new->run;
		return;
	},
	$help,
	'Run help (-h).',
);

# Test.
@ARGV = ();
stderr_is(
	sub {
		App::ISBN::Format->new->run;
		return;
	},
	$help,
	'Run help (no options).',
);

# Test.
@ARGV = (
	'978-80-253-4336-4',
);
my $right_ret = <<'END';
978-80-253-4336-4 -> 978-80-253-4336-4
END
stdout_is(
	sub {
		App::ISBN::Format->new->run;
		return;
	},
	$right_ret,
	'Check right ISBN format (978-80-253-4336-4).',
);

# Test.
@ARGV = (
	'9788025343364',
);
$right_ret = <<'END';
9788025343364 -> 978-80-253-4336-4
END
stdout_is(
	sub {
		App::ISBN::Format->new->run;
		return;
	},
	$right_ret,
	'Format ISBN (9788025343364 - format).',
);

# Test.
@ARGV = (
	'9788025343363',
);
$right_ret = <<'END';
9788025343363 -> 978-80-253-4336-4
END
stdout_is(
	sub {
		App::ISBN::Format->new->run;
		return;
	},
	$right_ret,
	'Format ISBN (9788025343363 - bad checksum).',
);
