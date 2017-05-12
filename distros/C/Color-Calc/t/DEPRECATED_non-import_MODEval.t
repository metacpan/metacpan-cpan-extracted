use Test::More tests => 49;
use Test::NoWarnings;
use Color::Calc();

local $Color::Calc::MODE = 'hex';
is(Color::Calc::get		('red'),		'ff0000');
is(Color::Calc::mix		('red','blue'),		'800080');

is(Color::Calc::blend_bw	('red'),		'ff8080');
is(Color::Calc::blend		('red'), 		'808080');
is(Color::Calc::bw		('red'),		'4d4d4d');
is(Color::Calc::contrast_bw	('red'),		'ffffff');
is(Color::Calc::contrast	('red'),		'00ffff');
is(Color::Calc::dark		('red'),		'800000');
is(Color::Calc::gray		('red'),		'4d4d4d');
is(Color::Calc::grey		('red'),		'4d4d4d');
is(Color::Calc::invert		('red'),		'00ffff');
is(Color::Calc::light		('red'),		'ff8080');

local $Color::Calc::MODE = 'html';
is(Color::Calc::get		('F00'),		'red');
is(Color::Calc::mix		('red','blue'),		'purple');

is(Color::Calc::blend_bw	('red'),		'#ff8080');
is(Color::Calc::blend		('red'), 		'gray');
is(Color::Calc::bw		('red'),		'#4d4d4d');
is(Color::Calc::contrast_bw	('red'),		'white');
is(Color::Calc::contrast	('red'),		'aqua');
is(Color::Calc::dark		('red'),		'maroon');
is(Color::Calc::gray		('red'),		'#4d4d4d');
is(Color::Calc::grey		('red'),		'#4d4d4d');
is(Color::Calc::invert		('red'),		'aqua');
is(Color::Calc::light		('red'),		'#ff8080');

local $Color::Calc::MODE = 'object';
SKIP: {
eval { require Graphics::ColorObject; };
skip "Graphics::ColorObject not installed", 12 if $@;

is(lc Color::Calc::get		('red')->as_RGBhex,		'ff0000');
is(lc Color::Calc::mix		('red','blue')->as_RGBhex,	'800080');

is(lc Color::Calc::blend_bw	('red')->as_RGBhex,		'ff8080');
is(lc Color::Calc::blend	('red')->as_RGBhex, 		'808080');
is(lc Color::Calc::bw		('red')->as_RGBhex,		'4d4d4d');
is(lc Color::Calc::contrast_bw	('red')->as_RGBhex,		'ffffff');
is(lc Color::Calc::contrast	('red')->as_RGBhex,		'00ffff');
is(lc Color::Calc::dark	('red')->as_RGBhex,		'800000');
is(lc Color::Calc::gray	('red')->as_RGBhex,		'4d4d4d');
is(lc Color::Calc::grey	('red')->as_RGBhex,		'4d4d4d');
is(lc Color::Calc::invert	('red')->as_RGBhex,		'00ffff');
is(lc Color::Calc::light	('red')->as_RGBhex,		'ff8080');
}

local $Color::Calc::MODE = 'tuple';
is(join(',',Color::Calc::get		('red')),		'0255,0,0');
is(join(',',Color::Calc::mix		('red','blue')),	'0128,0,0128');

is(join(',',Color::Calc::blend_bw	('red')),		'0255,0128,0128');
is(join(',',Color::Calc::blend		('red')), 		'0128,0128,0128');
is(join(',',Color::Calc::bw		('red')),		'77,77,77');
is(join(',',Color::Calc::contrast_bw	('red')),		'0255,0255,0255');
is(join(',',Color::Calc::contrast	('red')),		'0,0255,0255');
is(join(',',Color::Calc::dark		('red')),		'0128,0,0');
is(join(',',Color::Calc::gray		('red')),		'77,77,77');
is(join(',',Color::Calc::grey		('red')),		'77,77,77');
is(join(',',Color::Calc::invert	('red')),		'0,0255,0255');
is(join(',',Color::Calc::light		('red')),		'0255,0128,0128');
