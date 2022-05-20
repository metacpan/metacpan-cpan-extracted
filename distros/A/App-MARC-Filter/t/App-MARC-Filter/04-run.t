use strict;
use warnings;

use App::MARC::Filter;
use English;
use File::Object;
use File::Spec::Functions qw(abs2rel);
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 6;
use Test::NoWarnings;
use Test::Output;

my $data_dir = File::Object->new->up->dir('data');
my $script = abs2rel(File::Object->new->file('04-run.t')->s);
# XXX Hack for missing abs2rel on Windows.
if ($OSNAME eq 'MSWin32') {
	$script =~ s/\\/\//msg;
}

# Test.
@ARGV = (
	'-h',
);
my $right_ret = <<"END";
Usage: $script [-h] [-o format] [-r] [--version] marc_xml_file field subfield value
	-h		Print help.
	-o format	Output MARC format. Possible formats are ascii, xml.
	-r		Use value as Perl regexp.
	--version	Print version.
	marc_xml_file	MARC XML file.
	field		MARC field.
	subfield	MARC subfield.
	value		MARC field/subfield value to filter.
END
stderr_is(
	sub {
		App::MARC::Filter->new->run;
		return;
	},
	$right_ret,
	'Run help.',
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
