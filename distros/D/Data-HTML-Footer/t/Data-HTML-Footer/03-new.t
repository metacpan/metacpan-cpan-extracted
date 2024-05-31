use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Data::HTML::Footer;
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Footer->new;
isa_ok($obj, 'Data::HTML::Footer');

# Test.
$obj = Data::HTML::Footer->new(
	'author' => 'Michal',
	'author_url' => 'https://skim.cz',
	'copyright_years' => '2022-2024',
	'height' => '10px',
	'version' => 0.07,
	'version_url' => '/changes',
);
isa_ok($obj, 'Data::HTML::Footer');

# Test.
eval {
	Data::HTML::Footer->new(
		'author_url' => 'urn:isbn:9788072044948',
	);
};
is($EVAL_ERROR, "Parameter 'author_url' doesn't contain valid location.\n",
	"Parameter 'author_url' doesn't contain valid location (urn:isbn:9788072044948).");
clean();

# Test.
eval {
	Data::HTML::Footer->new(
		'height' => 12,
	);
};
is($EVAL_ERROR, "Parameter 'height' doesn't contain unit name.\n",
	"Parameter 'height' doesn't contain unit name (12).");
clean();

# Test.
eval {
	Data::HTML::Footer->new(
		'height' => '12xx',
	);
};
is($EVAL_ERROR, "Parameter 'height' contain bad unit.\n",
	"Parameter 'height' contain bad unit (12xx).");
clean();

# Test.
eval {
	Data::HTML::Footer->new(
		'height' => 'xx',
	);
};
is($EVAL_ERROR, "Parameter 'height' doesn't contain unit number.\n",
	"Parameter 'height' doesn't contain unit number (xx).");
clean();

# Test.
eval {
	Data::HTML::Footer->new(
		'version_url' => 'urn:isbn:9788072044948',
	);
};
is($EVAL_ERROR, "Parameter 'version_url' doesn't contain valid location.\n",
	"Parameter 'version_url' doesn't contain valid location (urn:isbn:9788072044948).");
clean();
