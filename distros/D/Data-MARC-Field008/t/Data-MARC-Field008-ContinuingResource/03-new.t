use strict;
use warnings;

use Data::MARC::Field008::ContinuingResource;
use English;
use Error::Pure::Utils qw(clean err_get);
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
## cnb003684882
my $obj = Data::MARC::Field008::ContinuingResource->new(
	'conference_publication' => '0',
	'entry_convention' => '2',
	'form_of_item' => 'o',
	'form_of_original_item' => ' ',
	'frequency' => ' ',
	'government_publication' => ' ',
	'nature_of_content' => '   ',
	'nature_of_entire_work' => ' ',
	'original_alphabet_or_script_of_title' => 'b',
	'regularity' => 'x',
	'type_of_continuing_resource' => 'w',
);
isa_ok($obj, 'Data::MARC::Field008::ContinuingResource');

# Test.
## cnb003684882
$obj = Data::MARC::Field008::ContinuingResource->new(
	'conference_publication' => '0',
	'entry_convention' => '2',
	'form_of_item' => 'o',
	'form_of_original_item' => ' ',
	'frequency' => ' ',
	'government_publication' => ' ',
	'nature_of_content' => '   ',
	'nature_of_entire_work' => ' ',
	'original_alphabet_or_script_of_title' => 'b',
	'raw' => ' x w o     0   b2',
	'regularity' => 'x',
	'type_of_continuing_resource' => 'w',
);
isa_ok($obj, 'Data::MARC::Field008::ContinuingResource');

# Test.
eval {
	Data::MARC::Field008::ContinuingResource->new;
};
is($EVAL_ERROR, "Couldn't create data object of continuing resource.\n",
	"Couldn't create data object of continuing resource.");
my @errors = err_get;
is(scalar @errors, 12, 'Number of errors (12).');
clean();
