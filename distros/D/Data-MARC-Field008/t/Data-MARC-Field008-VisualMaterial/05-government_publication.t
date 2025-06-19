use strict;
use warnings;

use Data::MARC::Field008::VisualMaterial;
use Test::More 'tests' => 2;
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
is($obj->government_publication, ' ', 'Get visual material government publication ( ).');
