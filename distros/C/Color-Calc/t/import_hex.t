use Test::More tests => 14;
use Test::NoWarnings;
use Color::Calc( 'OutputFormat' => 'hex' );

is(color_get		('red'),		'ff0000');
is(color    		('red'),		'ff0000');
is(color_mix		('red','blue'),		'800080');

is(color_blend_bw	('red'),		'ff8080');
is(color_blend		('red'), 		'808080');
is(color_bw		('red'),		'4d4d4d');
is(color_contrast_bw	('red'),		'ffffff');
is(color_contrast	('red'),		'00ffff');
is(color_dark		('red'),		'800000');
is(color_gray		('red'),		'4d4d4d');
is(color_grey		('red'),		'4d4d4d');
is(color_invert		('red'),		'00ffff');
is(color_light		('red'),		'ff8080');
