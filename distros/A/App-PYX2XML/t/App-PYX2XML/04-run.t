use strict;
use warnings;

use App::PYX2XML;
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use File::Object;
use Test::More 'tests' => 7;
use Test::NoWarnings;
use Test::Output;
use Unicode::UTF8 qw(decode_utf8);

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Test.
@ARGV = (
	$data_dir->file('element.pyx')->s,
);
my $right_ret = <<'END';
<element />
END
stdout_is(
	sub {
		App::PYX2XML->new->run;
		return;
	},
	$right_ret,
	'Run with simple element.',
);

# Test.
@ARGV = (
	$data_dir->file('element_with_content.pyx')->s,
);
$right_ret = <<'END';
<element>data</element>
END
stdout_is(
	sub {
		App::PYX2XML->new->run;
		return;
	},
	$right_ret,
	'Run with full element.',
);

# Test.
@ARGV = (
	'-i',
	$data_dir->file('element_with_content.pyx')->s,
);
$right_ret = <<'END';
<element>
  data
</element>
END
stdout_is(
	sub {
		App::PYX2XML->new->run;
		return;
	},
	$right_ret,
	'Run with full element in indent mode.',
);

# Test.
@ARGV = (
	$data_dir->file('element_utf8.pyx')->s,
);
$right_ret = <<'END';
<čupřina cíl="ředkev" />
END
stdout_is(
	sub {
		App::PYX2XML->new->run;
		return;
	},
	$right_ret,
	'Run with element in utf-8.',
);

# Test.
@ARGV = (
	'-e', 'latin2',
	$data_dir->file('element_latin2.pyx')->s,
);
$right_ret = <<'END';
<čupřina cíl="ředkev" />
END
stdout_is(
	sub {
		App::PYX2XML->new->run;
		return;
	},
	$right_ret,
	'Run with element in latin2.',
);

# Test.
@ARGV = (
	'-h',
);
$right_ret = <<'END';
Usage: t/App-PYX2XML/04-run.t [-e in_enc] [-h] [-i] [--version] [filename] [-]
	-e in_enc	Input encoding (default value is utf-8)
	-h		Print help.
	-i		Indent output.
	--version	Print version.
	[filename]	Process on filename
	[-]		Process on stdin
END
stderr_is(
	sub {
		App::PYX2XML->new->run;
		return;
	},
	$right_ret,
	'Run help.',
);
