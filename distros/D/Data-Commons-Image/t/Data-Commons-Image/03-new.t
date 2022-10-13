use strict;
use warnings;

use Data::Commons::Image;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = Data::Commons::Image->new(
	'commons_name' => 'Michal from Czechia.jpg',
);
isa_ok($obj, 'Data::Commons::Image');

# Test.
$obj = Data::Commons::Image->new(
	'comment' => 'Michal from Czechia',
	'commons_name' => 'Michal from Czechia.jpg',
	'height' => 2730,
	'id' => 1,
	'size' => 1040304,
	'url' => 'https://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg',
	'width' => 4096,
);
isa_ok($obj, 'Data::Commons::Image');

# Test.
eval {
	Data::Commons::Image->new;
};
is($EVAL_ERROR, "Parameter 'commons_name' is required.\n",
	"Parameter 'commons_name' is required.");
clean();

# Test.
eval {
	Data::Commons::Image->new(
		'commons_name' => 'Michal from Czechia.jpg',
		'comment' => 'x' x 1001,
	);
};
is($EVAL_ERROR, "Parameter 'comment' has length greater than '1000'.\n",
	"Parameter 'comment' has length greater than '1000'.");
clean();

# Test.
eval {
	Data::Commons::Image->new(
		'commons_name' => 'Michal from Czechia.jpg',
		'url' => 'x' x 300,
	);
};
is($EVAL_ERROR, "Parameter 'url' has length greater than '255'.\n",
	"Parameter 'url' has length greater than '255'.");
clean();
