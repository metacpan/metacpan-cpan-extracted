use strict;
use warnings;

use App::MARC::Filter;
use English;
use Error::Pure::Utils qw(clean);
use File::Object;
use File::Spec::Functions qw(abs2rel);
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 38;
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
	'-e',
	'-r',
	$data_dir->file('ex1.xml')->s,
	'710',
);
$right_ret = help();
stderr_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run help (-e and -r combination).',
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
	'-e',
	$data_dir->file('ex1.xml')->s,
	'710',
);
$right_ret = slurp($data_dir->file('ex1.xml')->s);
stdout_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run existence filter for MARC XML file with 1 record (710 exists).',
);

# Test.
@ARGV = (
	'-e',
	$data_dir->file('ex1.xml')->s,
	'710',
	'a',
);
$right_ret = slurp($data_dir->file('ex1.xml')->s);
stdout_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run existence filter for MARC XML file with 1 record (710a exists).',
);

# Test.
@ARGV = (
	'-i',
	'-e',
	'-n 1',
	$data_dir->file('ex3.xml')->s,
	'710',
);
$right_ret = slurp($data_dir->file('ex5.xml')->s);
stdout_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run existence inverse filter for MARC XML file with 1 record (710 not exists).',
);

# Test.
@ARGV = (
	'-e',
	$data_dir->file('ex1.xml')->s,
	'710',
	'a',
	'ignored-value',
);
$right_ret = help();
stderr_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run help (-e with unexpected subfield value).',
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
	'-i',
	$data_dir->file('ex1.xml')->s,
	'leader',
	'     nam a22        450x',
);
$right_ret = slurp($data_dir->file('ex1.xml')->s);
stdout_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run filter for MARC XML file with 1 record (leader != \'     nam a22        450x\').',
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
	'-i',
	$data_dir->file('ex1.xml')->s,
	'001',
	'ck8300077',
);
$right_ret = slurp($data_dir->file('ex1.xml')->s);
stdout_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run filter for MARC XML file with 1 record (001 != \'ck8300077\').',
);

# Test.
@ARGV = (
	$data_dir->file('ex1.xml')->s,
	'008.date1',
	'1982',
);
$right_ret = slurp($data_dir->file('ex1.xml')->s);
stdout_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run filter for MARC XML file with 1 record (008.date1 = 1982).',
);

# Test.
@ARGV = (
	$data_dir->file('ex1.xml')->s,
	'008.date2',
	'    ',
);
$right_ret = slurp($data_dir->file('ex1.xml')->s);
stdout_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run filter for MARC XML file with 1 record (008.date2 = \'    \').',
);

# Test.
@ARGV = (
	$data_dir->file('ex1.xml')->s,
	'008.date1',
	'1980..1985',
);
$right_ret = slurp($data_dir->file('ex1.xml')->s);
stdout_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run filter for MARC XML file with 1 record (008.date1 in range 1980..1985).',
);

# Test.
@ARGV = (
	$data_dir->file('ex1.xml')->s,
	'008.date1',
	'1983..1985',
);
stdout_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	'',
	'Run filter for MARC XML file with 0 record (008.date1 not in range 1983..1985).',
);

# Test.
@ARGV = (
	'-i',
	$data_dir->file('ex1.xml')->s,
	'008.date1',
	'1983..1985',
);
$right_ret = slurp($data_dir->file('ex1.xml')->s);
stdout_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run inverse filter for MARC XML file with 1 record (008.date1 not in range 1983..1985).',
);

# Test.
@ARGV = (
	$data_dir->file('ex1.xml')->s,
	'008.type_of_date',
	's',
);
$right_ret = slurp($data_dir->file('ex1.xml')->s);
stdout_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run filter for MARC XML file with 1 record (008.type_of_date = s).',
);

# Test.
@ARGV = (
	$data_dir->file('ex1.xml')->s,
	'008.language',
	'cze',
);
$right_ret = slurp($data_dir->file('ex1.xml')->s);
stdout_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run filter for MARC XML file with 1 record (008.language = cze).',
);

# Test.
@ARGV = (
	$data_dir->file('ex1.xml')->s,
	'008.foo',
	'bar',
);
$right_ret = help();
stderr_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run help for bad field 008 item (008.foo).',
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
	$data_dir->file('ex1.xml.bz2')->s,
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
	'Run filter for MARC XML file with 1 record (material_type = book, compressed input).',
);

# Test.
@ARGV = (
	'-i',
	$data_dir->file('ex1.xml')->s,
	'material_type',
	'computer_file',
);
$right_ret = slurp($data_dir->file('ex1.xml')->s);
stdout_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run filter for MARC XML file with 1 record (material_type != computer_file).',
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
	'Run filter for MARC XML file with 0 record (015a = cnb).',
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
	'-i',
	'-r',
	$data_dir->file('ex1.xml')->s,
	'015',
	'a',
	'cnc',
);
stdout_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run filter for MARC XML file with 1 record (015a !~ cnc).',
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
	$data_dir->file('ex1.xml')->s,
	'material_type',
	'bad_material_type',
);
eval {
	App::MARC::Filter->new->run;
};
is($EVAL_ERROR, "Bad material type.\n",
	"Bad material type (bad_material_type).");
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

# Test.
@ARGV = (
	$data_dir->file('ex4.mrc')->s,
	'leader',
	'01262nam a2200337   4500',
);
$right_ret = slurp($data_dir->file('ex4.xml')->s);
stdout_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run filter for MARC USMARC file with 1 record (leader = \'01262nam a2200337   4500\').',
);

# Test.
@ARGV = (
	$data_dir->file('ex4.mrc.gz')->s,
	'leader',
	'01262nam a2200337   4500',
);
$right_ret = slurp($data_dir->file('ex4.xml')->s);
stdout_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run filter for MARC USMARC file with 1 record (leader = \'01262nam a2200337   4500\', compressed input).',
);

# Test.
@ARGV = (
	'-o',
	'ascii',
	$data_dir->file('ex4.mrc')->s,
	'leader',
	'01262nam a2200337   4500',
);
$right_ret = slurp($data_dir->file('ex4.ascii')->s);
stdout_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run filter for MARC USMARC file with 1 record with ascii output (leader = \'01262nam a2200337   4500\').',
);

sub help {
	my $script = abs2rel(__FILE__);
	if ($OSNAME eq 'MSWin32') {
		$script =~ s/\\/\//msg;
	}
	my $help = <<"END";
Usage: $script [-e] [-h] [-i] [-n num] [-o format] [-r] [-v] [--version] marc_file search_item [sub_search_item] [value]
	-e		Match field/subfield existence.
	-h		Print help.
	-i		Invert searching.
	-n num		Number of records to output (default value is all records).
	-o format	Output MARC format. Possible formats are ascii, xml.
	-r		Use value as Perl regexp.
	-v		Verbose mode.
	--version	Print version.
	marc_file	MARC XML or USMARC file, could be compressed.
	search_item	Search item. See man page for more information.
	sub_search_item	Search sub item (optional in case of MARC field).
	value		Value to filter (required without -e).
END

	return $help;
}
