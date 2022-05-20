use strict;
use warnings;

use App::MARC::List;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = App::MARC::List->new;
isa_ok($obj, 'App::MARC::List');

# Test.
eval {
	App::MARC::List->new(
		'foo' => 'bar',
	);
};
is($EVAL_ERROR, "Unknown parameter 'foo'.\n", "Unknown parameter 'foo'.");
clean();
