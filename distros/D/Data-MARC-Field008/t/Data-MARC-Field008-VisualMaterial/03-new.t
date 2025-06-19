use strict;
use warnings;

use Data::MARC::Field008::VisualMaterial;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
## cnb003684150
my $obj = Data::MARC::Field008::VisualMaterial->new(
	'form_of_item' => ' ',
	'government_publication' => ' ',
	'running_time_for_motion_pictures_and_videorecordings' => 'nnn',
	'target_audience' => 'g',
	'technique' => 'n',
	'type_of_visual_material' => 'i',
);
isa_ok($obj, 'Data::MARC::Field008::VisualMaterial');

# Test.
## cnb003684150
$obj = Data::MARC::Field008::VisualMaterial->new(
	'form_of_item' => ' ',
	'government_publication' => ' ',
	'raw' => 'nnn g          in',
	'running_time_for_motion_pictures_and_videorecordings' => 'nnn',
	'target_audience' => 'g',
	'technique' => 'n',
	'type_of_visual_material' => 'i',
);
isa_ok($obj, 'Data::MARC::Field008::VisualMaterial');

# Test.
eval {
	Data::MARC::Field008::VisualMaterial->new(
		'raw' => '  ',
	);
};
is($EVAL_ERROR, "Parameter 'raw' has length different than '17'.\n",
	"Parameter 'raw' has length different than '17'.");
clean();
