use strict;
use warnings;

use Data::Image;
use DateTime;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $obj = Data::Image->new;
isa_ok($obj, 'Data::Image');

# Test.
$obj = Data::Image->new(
        'author' => 'Zuzana Zonova',
        'comment' => 'Michal from Czechia',
        'dt_created' => DateTime->new(
                'day' => 1,
                'month' => 1,
                'year' => 2022,
        ),
        'height' => 2730,
        'size' => 1040304,
        'url' => 'https://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg',
        'width' => 4096,
);
isa_ok($obj, 'Data::Image');

# Test.
eval {
	Data::Image->new(
		'author' => 'x' x 256,
	);
};
is($EVAL_ERROR, "Parameter 'author' has length greater than '255'.\n",
	"Parameter 'author' has length greater than '255'.");
clean();

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

# Test.
eval {
	Data::Image->new(
		'url' => 'urn:isbn:0451450523',
	);
};
is($EVAL_ERROR, "Parameter 'url' doesn't contain valid location.\n",
	"Parameter 'url' doesn't contain valid location (urn:isbn:0451450523).");
clean();
