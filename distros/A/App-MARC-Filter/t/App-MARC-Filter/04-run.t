use strict;
use warnings;

use App::MARC::Filter;
use English;
use Error::Pure::Utils qw(clean);
use File::Object;
use File::Spec::Functions qw(abs2rel);
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 16;
use Test::NoWarnings;
use Test::Output;
use Test::Warn 0.31;

my $data_dir = File::Object->new->up->dir('data');

# Test.
@ARGV = (
	'-h',
);
my $right_ret = help();
stderr_is(
	sub {
		App::MARC::Filter->new->run;
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
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run help (no arguments).',
);

# Test.
@ARGV = (
	$data_dir->file('ex1.xml')->s,
	'015',
	'a',
);
$right_ret = help();
stderr_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run help (no field/subfield value).',
);

# Test.
@ARGV = (
	$data_dir->file('ex1.xml')->s,
	'leader'
);
$right_ret = help();
stderr_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run help (no leader value).',
);

# Test.
@ARGV = (
	'-x',
);
$right_ret = help();
stderr_is(
	sub {
		warning_is { App::MARC::Filter->new->run; } "Unknown option: x\n",
			'Warning about bad argument';
		return;
	},
	$right_ret,
	'Run help (-x - bad option).',
);

# Test.
@ARGV = (
	$data_dir->file('ex1.xml')->s,
	'015',
	'a',
	'cnb000000096',
);
$right_ret = slurp($data_dir->file('ex1.xml')->s);
stdout_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run filter for MARC XML file with 1 record (015a = cnb000000096).',
);

# Test.
@ARGV = (
	'-n 1',
	$data_dir->file('ex3.xml')->s,
	'040',
	'a',
	'ABA001',
);
$right_ret = slurp($data_dir->file('ex1.xml')->s);
stdout_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run filter for MARC XML file with 1 record (all 040a=ABA001, but filter to 1 output record).',
);

# Test.
@ARGV = (
	$data_dir->file('ex1.xml')->s,
	'leader',
	'     nam a22        4500',
);
$right_ret = slurp($data_dir->file('ex1.xml')->s);
stdout_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run filter for MARC XML file with 1 record (leader = \'     nam a22        4500\').',
);

# Test.
@ARGV = (
	$data_dir->file('ex1.xml')->s,
	'001',
	'ck8300078',
);
$right_ret = slurp($data_dir->file('ex1.xml')->s);
stdout_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run filter for MARC XML file with 1 record (001 = \'ck8300078\').',
);

# Test.
@ARGV = (
	$data_dir->file('ex1.xml')->s,
	'material_type',
	'book',
);
$right_ret = slurp($data_dir->file('ex1.xml')->s);
stdout_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run filter for MARC XML file with 1 record (material_type = book).',
);

# Test.
@ARGV = (
	$data_dir->file('ex1.xml')->s,
	'015',
	'a',
	'cnb',
);
stdout_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	'',
	'Run filter for MARC XML file with 1 record (015a = cnb).',
);

# Test.
@ARGV = (
	'-r',
	$data_dir->file('ex1.xml')->s,
	'015',
	'a',
	'cnb',
);
stdout_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run filter for MARC XML file with 1 record (015a ~ cnb).',
);

# Test.
@ARGV = (
	'-o',
	'bad',
	$data_dir->file('ex1.xml')->s,
	'015',
	'a',
	'cnb',
);
eval {
	App::MARC::Filter->new->run;
};
is($EVAL_ERROR, "Output format 'bad' doesn't supported.\n",
	"Output format 'bad' doesn't supported.");
clean();

# Test.
@ARGV = (
	$data_dir->file('ex2.xml')->s,
	'015',
	'a',
	'cnb001489030',
);
stderr_like(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	qr{^Cannot process '1' record\. Error: Field 300 must have indicators \(use ' ' for empty indicators\)},
	'Run filter for MARC XML file with 1 record (with error).',
);

sub help {
	my $script = abs2rel(File::Object->new->file('04-run.t')->s);
	# XXX Hack for missing abs2rel on Windows.
	if ($OSNAME eq 'MSWin32') {
		$script =~ s/\\/\//msg;
	}
	my $help = <<"END";
Usage: $script [-h] [-n num] [-o format] [-r] [-v] [--version] marc_xml_file search_item [sub_search_item] value
	-h		Print help.
	-n num		Number of records to output (default value is all records).
	-o format	Output MARC format. Possible formats are ascii, xml.
	-r		Use value as Perl regexp.
	-v		Verbose mode.
	--version	Print version.
	marc_xml_file	MARC XML file.
	search_item	Search item.
	sub_search_item	Search sub item (required in case of MARC field).
	value		Value to filter.
END

	return $help;
}
