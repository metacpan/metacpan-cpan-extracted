use strict;
use warnings;

use App::Bin::Search;
use English;
use File::Object;
use File::Spec::Functions qw(abs2rel);
use Test::More 'tests' => 8;
use Test::NoWarnings;
use Test::Output;

# Common.
my $script = abs2rel(File::Object->new->file('04-run.t')->s);
# XXX Hack for missing abs2rel on Windows.
if ($OSNAME eq 'MSWin32') {
	$script =~ s/\\/\//msg;
}
my $help = <<"END";
Usage: $script [-b] [-h] [-v] [--version] hex_stream search
	-b		Print in binary (default hexadecimal).
	-h		Print help.
	-v		Verbose mode.
	--version	Print version.
	hex_stream	Input hexadecimal stream.
	search		Search string (in hex).
END

# Test.
@ARGV = (
	'-h',
);
stderr_is(
	sub {
		App::Bin::Search->new->run;
		return;
	},
	$help,
	'Run help (-h).',
);

# Test.
@ARGV = ();
stderr_is(
	sub {
		App::Bin::Search->new->run;
		return;
	},
	$help,
	'Run help (no options).',
);

# Test.
@ARGV = (
	'FFABCD',
	'D5',
);
my $right_ret = <<"END";
Found D5E68 at 8 bit
END
stdout_is(
	sub {
		App::Bin::Search->new->run;
		return;
	},
	$right_ret,
	'Search D5 in FFABCD (default - hexadecimal output).',
);

# Test.
@ARGV = (
	'-v',
	'FFABCD',
	'D5',
);
$right_ret = <<"END";
Hexadecimal stream: FFABCD
Size of hexadecimal stream: 24
Looking for: D5
FFABCD at 1bit
FF579A at 2bit
FEAF34 at 3bit
FD5E68 at 4bit
FABCD at 5bit
F579A at 6bit
EAF34 at 7bit
D5E68 at 8bit
Found D5E68 at 8 bit
ABCD at 9bit
579A at 10bit
AF34 at 11bit
5E68 at 12bit
BCD at 13bit
79A at 14bit
F34 at 15bit
E68 at 16bit
CD at 17bit
9A at 18bit
34 at 19bit
68 at 20bit
D at 21bit
A at 22bit
4 at 23bit
8 at 24bit
END
stdout_is(
	sub {
		App::Bin::Search->new->run;
		return;
	},
	$right_ret,
	'Search D5 in FFABCD (default - hexadecimal output, verbose).',
);

# Test.
@ARGV = (
	'-b',
	'-v',
	'FFABCD',
	'D5',
);
$right_ret = <<"END";
Hexadecimal stream: 111111111010101111001101
Size of hexadecimal stream: 24
Looking for: 11010101
111111111010101111001101 at 1bit
11111111010101111001101 at 2bit
1111111010101111001101 at 3bit
111111010101111001101 at 4bit
11111010101111001101 at 5bit
1111010101111001101 at 6bit
111010101111001101 at 7bit
11010101111001101 at 8bit
Found 11010101111001101 at 8 bit
1010101111001101 at 9bit
010101111001101 at 10bit
10101111001101 at 11bit
0101111001101 at 12bit
101111001101 at 13bit
01111001101 at 14bit
1111001101 at 15bit
111001101 at 16bit
11001101 at 17bit
1001101 at 18bit
001101 at 19bit
01101 at 20bit
1101 at 21bit
101 at 22bit
01 at 23bit
1 at 24bit
END
stdout_is(
	sub {
		App::Bin::Search->new->run;
		return;
	},
	$right_ret,
	'Search D5 in FFABCD (binary output, verbose).',
);

# Test.
@ARGV = (
	'-b',
	'FFABCD',
	'D5',
);
$right_ret = <<"END";
Found 11010101111001101 at 8 bit
END
stdout_is(
	sub {
		App::Bin::Search->new->run;
		return;
	},
	$right_ret,
	'Search D5 in FFABCD (binary output).',
);

# Test.
@ARGV = (
	'FFABCD',
	'FF',
);
$right_ret = <<"END";
Found FFABCD at 1 bit
Found FF579A at 2 bit
END
stdout_is(
	sub {
		App::Bin::Search->new->run;
		return;
	},
	$right_ret,
	'Search FF in FFABCD (default - hexadecimal output).',
);
