use strict;
use warnings;

use App::Wikidata::Template::CS::CitaceMonografie;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = App::Wikidata::Template::CS::CitaceMonografie->new;
isa_ok($obj, 'App::Wikidata::Template::CS::CitaceMonografie');

# Test.
eval {
	App::Wikidata::Template::CS::CitaceMonografie->new(
		'cb_wikidata' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'cb_wikidata' must be a code.\n",
	"Parameter 'cb_wikidata' must be a code.");
clean();

# Test.
eval {
	App::Wikidata::Template::CS::CitaceMonografie->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad \'something\' parameter.');
clean();
