use strict;
use warnings;

use App::HL7::Send;
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
Usage: $script [-h] [--version] host port hl7_file|-
	-h		Print help.
	--version	Print version.
END
stderr_is(
	sub {
		App::HL7::Send->new->run;
		return;
	},
	$right_ret,
	'Run help.',
);
