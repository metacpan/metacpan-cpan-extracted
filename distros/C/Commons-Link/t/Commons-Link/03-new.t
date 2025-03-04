use strict;
use warnings;

use Commons::Link;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Commons::Link->new;
isa_ok($obj, 'Commons::Link');

# Test.
$obj = Commons::Link->new(
	'utf-8' => 0,
);
isa_ok($obj, 'Commons::Link');

# Test.
eval {
	Commons::Link->new(
		'utf-8' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'utf-8' must be a bool (0/1).\n",
	"Parameter 'utf-8' must be a bool (0/1) (bad).");
clean();
