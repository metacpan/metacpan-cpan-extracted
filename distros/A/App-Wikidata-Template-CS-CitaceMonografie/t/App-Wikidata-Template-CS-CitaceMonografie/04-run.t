use strict;
use warnings;

use App::Wikidata::Template::CS::CitaceMonografie;
use English;
use Error::Pure::Utils qw(clean);
use File::Object;
use File::Spec::Functions qw(abs2rel catfile);
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Test::Output;
use Test::Warn;

# Test.
@ARGV = (
	'-h',
);
my $right_ret = help();
stderr_is(
	sub {
		App::Wikidata::Template::CS::CitaceMonografie->new->run;
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
		App::Wikidata::Template::CS::CitaceMonografie->new->run;
		return;
	},
	$right_ret,
	'Run help (no Wikidata id).',
);

# Test.
@ARGV = (
	'-x',
);
$right_ret = help();
stderr_is(
	sub {
		warning_is { App::Wikidata::Template::CS::CitaceMonografie->new->run; } "Unknown option: x\n",
			'Warning about bad argument';
		return;
	},
	$right_ret,
	'Run help (-x - bad option).',
);

sub help {
	my $script = abs2rel(File::Object->new->file('04-run.t')->s);
	# XXX Hack for missing abs2rel on Windows.
	if ($OSNAME eq 'MSWin32') {
		$script =~ s/\\/\//msg;
	}
	my $help = <<"END";
Usage: $script [-h] [-l lang] [-m mediawiki_site] [-p] [--version] wd_id
	-h			Print help.
	-l lang			Language used (default is English = en)
	-m mediawiki_site	MediaWiki site (default is www.wikidata.org).
	-p			Pretty print.
	--version		Print version.
	wd_id			Wikidata id (qid or pid or lid).
END

	return $help;
}
