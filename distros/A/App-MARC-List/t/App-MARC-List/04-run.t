use strict;
use warnings;

use App::MARC::List;
use English;
use Error::Pure::Utils qw(clean);
use File::Object;
use File::Spec::Functions qw(abs2rel);
use Test::More 'tests' => 9;
use Test::NoWarnings;
use Test::Output;
use Test::Warn;

my $data_dir = File::Object->new->up->dir('data');

# Test.
@ARGV = (
	'-h',
);
my $right_ret = help();
stderr_is(
	sub {
		App::MARC::List->new->run;
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
		App::MARC::List->new->run;
		return;
	},
	$right_ret,
	'Run help (no MARC file).',
);

# Test.
@ARGV = (
	'-x',
);
$right_ret = help();
stderr_is(
	sub {
		warning_is { App::MARC::List->new->run; } "Unknown option: x\n",
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
);
$right_ret = <<'END';
cnb000000096
END
stdout_is(
	sub {
		App::MARC::List->new->run;
		return;
	},
	$right_ret,
	'Run list for MARC XML file with 1 record (015a = cnb000000096).',
);

# Test.
@ARGV = (
	$data_dir->file('ex2.xml')->s,
	'015',
	'a',
);
stderr_like(
	sub {
		App::MARC::List->new->run;
		return;
	},
	qr{^Cannot process '1' record\. Error: Field 300 must have indicators \(use ' ' for empty indicators\)},
	'Run filter for MARC XML file with 1 record (with error).',
);

# Test.
@ARGV = (
	$data_dir->file('ex1.xml')->s,
);
eval {
	App::MARC::List->new->run;
};
is($EVAL_ERROR, "Field and subfield is required.\n", "Field and subfield is required.");
clean();

# Test.
@ARGV = (
	$data_dir->file('ex1.xml')->s,
	'015',
);
eval {
	App::MARC::List->new->run;
};
is($EVAL_ERROR, "Field and subfield is required.\n", "Field and subfield is required.");
clean();

sub help {
	my $script = abs2rel(File::Object->new->file('04-run.t')->s);
	# XXX Hack for missing abs2rel on Windows.
	if ($OSNAME eq 'MSWin32') {
		$script =~ s/\\/\//msg;
	}
	my $help = <<"END";
Usage: $script [-h] [--version] marc_xml_file field subfield
	-h		Print help.
	--version	Print version.
	marc_xml_file	MARC XML file.
	field		MARC field.
	subfield	MARC subfield.
END

	return $help;
}
