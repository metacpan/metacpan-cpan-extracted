use strict;
use warnings;

use App::Wikidata::Print;
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
Usage: $script [-h] [-l lang] [-m mediawiki_site] [--version] wd_id
	-h			Print help.
	-l lang			Language used (default is English = en).
	-m mediawiki_site	MediaWiki site (default is www.wikidata.org).
	--version		Print version.
	wd_id			Wikidata id (qid or pid or lid).
END
stderr_is(
	sub {
		App::Wikidata::Print->new->run;
		return;
	},
	$right_ret,
	'Run help.',
);
