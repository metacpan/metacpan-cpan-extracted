use Test::More tests => 14;
use Test::NoWarnings;
use Color::Calc( 'OutputFormat' => 'html' );

is(color_get		('F00'),		'red');
is(color    		('F00'),		'red');
is(color_mix		('red','blue'),		'purple');

is(color_blend_bw	('red'),		'#ff8080');
is(color_blend		('red'), 		'gray');
is(color_bw		('red'),		'#4d4d4d');
is(color_contrast_bw	('red'),		'white');
is(color_contrast	('red'),		'aqua');
is(color_dark		('red'),		'maroon');
is(color_gray		('red'),		'#4d4d4d');
is(color_grey		('red'),		'#4d4d4d');
is(color_invert		('red'),		'aqua');
is(color_light		('red'),		'#ff8080');
