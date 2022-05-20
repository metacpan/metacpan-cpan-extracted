use strict;
use warnings;

use App::MARC::Count;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = App::MARC::Count->new;
isa_ok($obj, 'App::MARC::Count');

# Test.
eval {
	App::MARC::Count->new(
		'foo' => 'bar',
	);
};
is($EVAL_ERROR, "Unknown parameter 'foo'.\n", "Unknown parameter 'foo'.");
clean();
