use strict;
use warnings;

use App::MARC::Filter;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = App::MARC::Filter->new;
isa_ok($obj, 'App::MARC::Filter');

# Test.
eval {
	App::MARC::Filter->new(
		'foo' => 'bar',
	);
};
is($EVAL_ERROR, "Unknown parameter 'foo'.\n", "Unknown parameter 'foo'.");
clean();
