use Test::More tests => 53;
use Test::NoWarnings;
use Color::Calc;

local $Color::Calc::MODE = 'hex';
is(color_get		('red'),		'ff0000');
is(color		('red'),		'ff0000');
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

local $Color::Calc::MODE = 'html';
is(color_get		('F00'),		'red');
is(color		('F00'),		'red');
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

local $Color::Calc::MODE = 'object';
SKIP: {
eval { require Graphics::ColorObject; };
skip "Graphics::ColorObject not installed", 13 if $@;

is(lc color_get		('red')->as_RGBhex,		'ff0000');
is(lc color		('red')->as_RGBhex,		'ff0000');
is(lc color_mix		('red','blue')->as_RGBhex,	'800080');

is(lc color_blend_bw	('red')->as_RGBhex,		'ff8080');
is(lc color_blend	('red')->as_RGBhex, 		'808080');
is(lc color_bw		('red')->as_RGBhex,		'4d4d4d');
is(lc color_contrast_bw	('red')->as_RGBhex,		'ffffff');
is(lc color_contrast	('red')->as_RGBhex,		'00ffff');
is(lc color_dark	('red')->as_RGBhex,		'800000');
is(lc color_gray	('red')->as_RGBhex,		'4d4d4d');
is(lc color_grey	('red')->as_RGBhex,		'4d4d4d');
is(lc color_invert	('red')->as_RGBhex,		'00ffff');
is(lc color_light	('red')->as_RGBhex,		'ff8080');
}

local $Color::Calc::MODE = 'tuple';
is(join(',',color_get		('red')),		'0255,0,0');
is(join(',',color		('red')),		'0255,0,0');
is(join(',',color_mix		('red','blue')),	'0128,0,0128');

is(join(',',color_blend_bw	('red')),		'0255,0128,0128');
is(join(',',color_blend		('red')), 		'0128,0128,0128');
is(join(',',color_bw		('red')),		'77,77,77');
is(join(',',color_contrast_bw	('red')),		'0255,0255,0255');
is(join(',',color_contrast	('red')),		'0,0255,0255');
is(join(',',color_dark		('red')),		'0128,0,0');
is(join(',',color_gray		('red')),		'77,77,77');
is(join(',',color_grey		('red')),		'77,77,77');
is(join(',',color_invert	('red')),		'0,0255,0255');
is(join(',',color_light		('red')),		'0255,0128,0128');
