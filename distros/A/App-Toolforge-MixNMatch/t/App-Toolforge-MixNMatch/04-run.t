use strict;
use warnings;

use App::Toolforge::MixNMatch;
use English;
use File::Object;
use File::Spec::Functions qw(abs2rel);
use Test::More 'tests' => 2;
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
Usage: $script [-h] [--version] [command] [command_args ..]
	-h		Print help.
	--version	Print version.
	command		Command (diff, download, print).

	command 'diff' arguments:
		json_file1 - JSON file #1
		json_file2 - JSON file #2
		[print_options] - Print options (type, count, year_months, users)
	command 'download' arguments:
		catalog_id - Catalog ID
		[output_file] - Output file (default is catalog_id.json)
	command 'print' arguments:
		json_file or catalog_id - Catalog ID or JSON file
		[print_options] - Print options (type, count, year_months, users)
END
stderr_is(
	sub {
		App::Toolforge::MixNMatch->new->run;
		return;
	},
	$right_ret,
	'Run help.',
);
