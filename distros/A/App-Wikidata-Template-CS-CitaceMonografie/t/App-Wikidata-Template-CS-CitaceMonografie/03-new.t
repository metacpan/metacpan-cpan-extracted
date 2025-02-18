use strict;
use warnings;

use App::Wikidata::Template::CS::CitaceMonografie;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = App::Wikidata::Template::CS::CitaceMonografie->new;
isa_ok($obj, 'App::Wikidata::Template::CS::CitaceMonografie');

# Test.
eval {
	App::Wikidata::Template::CS::CitaceMonografie->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad \'something\' parameter.');
clean();
