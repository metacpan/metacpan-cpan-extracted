use strict;
use warnings;

use Data::MARC::Field008::MixedMaterial;
use English;
use Error::Pure::Utils qw(clean err_get);
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = Data::MARC::Field008::MixedMaterial->new(
	'form_of_item' => 'r',
);
isa_ok($obj, 'Data::MARC::Field008::MixedMaterial');

# Test.
$obj = Data::MARC::Field008::MixedMaterial->new(
	'form_of_item' => 'r',
	'raw' => '     r           ',
);
isa_ok($obj, 'Data::MARC::Field008::MixedMaterial');

# Test.
eval {
	Data::MARC::Field008::MixedMaterial->new(
		'raw' => '     r           ',
	);
};
my @errors = err_get();
is($errors[0]->{'msg'}->[0], "Parameter 'form_of_item' is required.",
	"Parameter 'form_of_item' is required.");
is($errors[1]->{'msg'}->[0], "Couldn't create data object of mixed material.",
	"Couldn't create data object of mixed material.");
clean();

# Test.
eval {
	Data::MARC::Field008::MixedMaterial->new(
		'raw' => '     r      ',
	);
};
is($EVAL_ERROR, "Parameter 'raw' has length different than '17'.\n",
	"Parameter 'raw' has length different than '17'.");
clean();
