use strict;
use warnings;

use App::MARC::Validator;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = App::MARC::Validator->new;
isa_ok($obj, 'App::MARC::Validator');

# Test.
eval {
	App::MARC::Validator->new(
		'foo' => 'bar',
	);
};
is($EVAL_ERROR, "Unknown parameter 'foo'.\n", "Unknown parameter 'foo'.");
clean();
