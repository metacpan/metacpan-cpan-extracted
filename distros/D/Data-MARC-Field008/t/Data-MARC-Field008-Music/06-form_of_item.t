use strict;
use warnings;

use Data::MARC::Field008::Music;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::MARC::Field008::Music->new(
	'accompanying_matter' => '      ',
	'form_of_composition' => 'sg',
	'form_of_item' => ' ',
	'format_of_music' => 'z',
	'literary_text_for_sound_recordings' => 'nn',
	'music_parts' => ' ',
	'target_audience' => 'g',
	'transposition_and_arrangement' => ' ',
);
is($obj->form_of_item, ' ', 'Get form of item ( ).');
