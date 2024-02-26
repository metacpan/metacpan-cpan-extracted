use strict;
use warnings;

use App::ISBN::Check;
use English;
use File::Object;
use File::Spec::Functions qw(abs2rel);
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Test::Output;

# Common.
my $script = abs2rel(File::Object->new->file('04-run.t')->s);
# XXX Hack for missing abs2rel on Windows.
if ($OSNAME eq 'MSWin32') {
	$script =~ s/\\/\//msg;
}
my $help = <<"END";
Usage: $script [-h] [--version] file_with_isbns
	-h		Print help.
	--version	Print version.
	file_with_isbns	File with ISBN strings, one per line.
END
my $data = File::Object->new->up->dir('data');

# Test.
@ARGV = (
	'-h',
);
stderr_is(
	sub {
		App::ISBN::Check->new->run;
		return;
	},
	$help,
	'Run help (-h).',
);

# Test.
@ARGV = ();
stderr_is(
	sub {
		App::ISBN::Check->new->run;
		return;
	},
	$help,
	'Run help (no options).',
);

# Test.
@ARGV = (
	$data->file('right_isbns.txt')->s,
);
stdout_is(
	sub {
		App::ISBN::Check->new->run;
		return;
	},
	'',
	'Check right ISBNs (right_isbns.txt).',
);

# Test.
@ARGV = (
	$data->file('bad_isbns.txt')->s,
);
my $right_ret = <<'END';
9788025343363: Different after format (978-80-253-4336-4).
9788025343364: Different after format (978-80-253-4336-4).
978802534336: Cannot parse.
9656123456: Not valid.
END
stderr_is(
	sub {
		App::ISBN::Check->new->run;
		return;
	},
	$right_ret,
	'Check bad ISBNs (bad_isbns.txt).',
);
