use strict;
use warnings;

use App::MARC::Count;
use English;
use File::Object;
use File::Spec::Functions qw(abs2rel);
use Test::More 'tests' => 8;
use Test::NoWarnings;
use Test::Output;
use Test::Warn 0.31;

# Data dir.
my $data_dir = File::Object->new->up->dir('data');

# Test.
@ARGV = (
	'-h',
);
my $right_ret = help();
stderr_is(
	sub {
		App::MARC::Count->new->run;
		return;
	},
	$right_ret,
	'Run help.',
);

# Test.
@ARGV = ();
$right_ret = help();
stderr_is(
	sub {
		App::MARC::Count->new->run;
		return;
	},
	$right_ret,
	'Run help (no MARC XML file).',
);

# Test.
@ARGV = (
	'-x',
);
$right_ret = help();
stderr_is(
	sub {
		warning_is { App::MARC::Count->new->run; } "Unknown option: x\n",
			'Warning about bad argument';
		return;
	},
	$right_ret,
	'Run help (-x - bad option).',
);

# Test.
@ARGV = (
	$data_dir->file('ex1.xml')->s,
);
stdout_is(
	sub {
		App::MARC::Count->new->run;
		return;
	},
	"2\n",
	'Run count for MARC XML file with 3 records.',
);

# Test.
@ARGV = (
	$data_dir->file('ex2.xml')->s,
);
combined_like(
	sub {
		App::MARC::Count->new->run;
		return;
	},
	qr{^Cannot process '1' record\. Error: Field 300 must have indicators \(use ' ' for empty indicators\)},
	'Run count for MARC XML file with 1 records (with error).',
);

# Test.
@ARGV = (
	$data_dir->file('ex3.xml')->s,
);
combined_like(
	sub {
		App::MARC::Count->new->run;
		return;
	},
	qr{^Cannot process '2' record\. Previous record is Služby v systému národních výborů : vybrané kapitoly : určeno pro posl. fak. obchodní, obor Ekonomika služeb a cestovního ruchu / Vladislav Gabriel, Ladislav Zapadlo\nError: Field 300 must have indicators \(use ' ' for empty indicators\)},
	'Run count for MARC XML file with 2 records (second is with error).',
);

sub help {
	my $script = abs2rel(File::Object->new->file('04-run.t')->s);
	# XXX Hack for missing abs2rel on Windows.
	if ($OSNAME eq 'MSWin32') {
		$script =~ s/\\/\//msg;
	}
	my $help = <<"END";
Usage: $script [-h] [--version] marc_xml_file
	-h		Print help.
	--version	Print version.
	marc_xml_file	MARC XML file.
END

	return $help;
}
