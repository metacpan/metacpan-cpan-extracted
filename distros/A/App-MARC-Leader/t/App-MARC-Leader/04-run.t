use strict;
use warnings;

use App::MARC::Leader;
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
Usage: $script [-a] [-d] [-f marc_xml_file] [-h] [--version] [leader_string]
	-a			Print with ANSI colors (or use NO_COLOR/COLOR env variables).
	-d			Don't print description.
	-f marc_xml_file	MARC XML file.
	-h			Print help.
	--version		Print version.
	leader_string		MARC Leader string.
END
stderr_is(
	sub {
		App::MARC::Leader->new->run;
		return;
	},
	$right_ret,
	'Run help.',
);
