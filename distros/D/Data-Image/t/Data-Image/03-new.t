use strict;
use warnings;

use Data::Image;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Data::Image->new;
isa_ok($obj, 'Data::Image');

# Test.
$obj = Data::Image->new(
	'comment' => 'Michal from Czechia',
	'id' => 1,
	'url' => 'https://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg',
);
isa_ok($obj, 'Data::Image');

# Test.
eval {
	Data::Image->new(
		'comment' => 'x' x 1001,
	);
};
is($EVAL_ERROR, "Parameter 'comment' has length greater than '1000'.\n",
	"Parameter 'comment' has length greater than '1000'.");
clean();

# Test.
eval {
	Data::Image->new(
		'url' => 'x' x 300,
	);
};
is($EVAL_ERROR, "Parameter 'url' has length greater than '255'.\n",
	"Parameter 'url' has length greater than '255'.");
clean();
