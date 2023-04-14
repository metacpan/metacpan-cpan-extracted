use strict;
use warnings;

use App::Pod::Example;
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
eval {
	App::Pod::Example->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Bad parameter \'\'.');
clean();

# Test.
eval {
	App::Pod::Example->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad parameter \'something\'.');
clean();
