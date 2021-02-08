use strict;
use warnings;

use App::Translit::String;
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 7;
use Test::NoWarnings;
use Test::Warnings qw(warning :no_end_test);
use Test::Output;
use Unicode::UTF8 qw(decode_utf8);

# Test.
@ARGV = (
	decode_utf8('Российская Федерация'),
);
my $right_ret = <<'END';
Rossijskaja Federacija
END
stdout_is(
	sub {
		App::Translit::String->new->run;
		return;
	},
	$right_ret,
	'Run with transliteration.',
);

# Test.
@ARGV = (
	'-r',
	'Rossijskaja Federacija',
);
$right_ret = <<'END';
Российскайа Федерацийа
END
stdout_is(
	sub {
		App::Translit::String->new->run;
		return;
	},
	$right_ret,
	'Run with reverse transliteration.',
);

# Test.
@ARGV = (
	'-r',
	'-t', 'ISO 843',
	'Elláda',
);
eval {
	App::Translit::String->new->run;
};
is($EVAL_ERROR, "Cannot transliterate string.\n",
	'Run with not possible reverse transliteration (Greek/ISO 843).');
clean();

# Test.
@ARGV = (
	'-h',
);
$right_ret = <<'END';
Usage: t/App-Translit-String/04-run.t [-h] [-r] [-t table] [--version]
	string

	-h		Print help.
	-r		Reverse transliteration.
	-t table	Transliteration table (default value is 'ISO/R 9').
	--version	Print version.
END
stderr_is(
	sub {
		App::Translit::String->new->run;
		return;
	},
	$right_ret,
	'Run help.',
);

# Test.
@ARGV = (
	'-q',
);
$right_ret = <<'END';
Usage: t/App-Translit-String/04-run.t [-h] [-r] [-t table] [--version]
	string

	-h		Print help.
	-r		Reverse transliteration.
	-t table	Transliteration table (default value is 'ISO/R 9').
	--version	Print version.
END
my $warning;
stderr_is(
	sub {
		$warning = warning {
			App::Translit::String->new->run;
		};
		return;
	},
	$right_ret,
	'Run help with bad option (-q).',
);
is($warning, "Unknown option: q\n", 'Warning for unknown option.');
