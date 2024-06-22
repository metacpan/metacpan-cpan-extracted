use strict;
use warnings;

use App::Wikidata::Print;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = App::Wikidata::Print->new;
isa_ok($obj, 'App::Wikidata::Print');

# Test.
eval {
	App::Wikidata::Print->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Bad \'\' parameter.');
clean();

# Test.
eval {
	App::Wikidata::Print->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad \'something\' parameter.');
clean();
