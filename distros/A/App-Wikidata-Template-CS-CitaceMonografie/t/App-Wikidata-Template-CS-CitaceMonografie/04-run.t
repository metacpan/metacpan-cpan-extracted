use strict;
use warnings;

use App::Wikidata::Template::CS::CitaceMonografie;
use Cpanel::JSON::XS qw(decode_json);
use English;
use Error::Pure::Utils qw(clean);
use File::Object;
use File::Spec::Functions qw(abs2rel catfile);
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 8;
use Test::NoWarnings;
use Test::Output;
use Test::Warn 0.31;
use Wikibase::Datatype::Item;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Struct::Item qw(struct2obj);
use Wikibase::Datatype::Value;

# Data dir.
my $data_dir = File::Object->new->up->dir('data');

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

# Test.
@ARGV = (
	'Q79324593',
);
eval {
	App::Wikidata::Template::CS::CitaceMonografie->new(
		'cb_wikidata' => sub {
			my ($self, $wd_id) = @_;
			my $item = Wikibase::Datatype::Item->new;
			return $item;
		},
	)->run;
};
is($EVAL_ERROR, "This item isn't book edition.\n",
	"This item isn't book edition (blank Wikibase::Datatype::Item instance).");
clean();

# Test.
@ARGV = (
	'Q138471014',
);
$right_ret = <<'END';
{{Citace monografie | autor = Bronislava Dresslerová | autor2 = Gabriel Gombik | autor3 = Michal Hejč | edice = Operační systémy | isbn = 80-7226-114-2 | místo = Praha | počet stran = 1175 | překladatelé = Jiři Veselský, Jan Škvařil | rok = 1998 | titul = Linux: dokumentační projekt | vydavatel = Computer Press }}
END
my $exit_code = 1;
stdout_is(
	sub {
		$exit_code = App::Wikidata::Template::CS::CitaceMonografie->new(
			'cb_wikidata' => sub {
				my ($self, $wd_id) = @_;
				my $item;
				if (-r $data_dir->file($wd_id.'.json')->s) {
					my $json = slurp($data_dir->file($wd_id.'.json')->s);
					my $json_hr = decode_json($json);
					$item = struct2obj($json_hr->[0]);
				}
				return $item;
			},
		)->run;
		return;
	},
	$right_ret,
	'Process example Wikidata JSON structure.',
);
is($exit_code, 0, 'Exit code (0).');

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
