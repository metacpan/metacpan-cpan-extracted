use Test::More tests => (12*4) + 1;
use Test::NoWarnings;
use Color::Calc();

is(Color::Calc::get_hex		('red'),		'ff0000');
is(Color::Calc::mix_hex		('red','blue'),		'800080');

is(Color::Calc::blend_bw_hex		('red'),		'ff8080');
is(Color::Calc::blend_hex		('red'), 		'808080');
is(Color::Calc::bw_hex			('red'),		'4d4d4d');
is(Color::Calc::contrast_bw_hex	('red'),		'ffffff');
is(Color::Calc::contrast_hex		('red'),		'00ffff');
is(Color::Calc::dark_hex		('red'),		'800000');
is(Color::Calc::gray_hex		('red'),		'4d4d4d');
is(Color::Calc::grey_hex		('red'),		'4d4d4d');
is(Color::Calc::invert_hex		('red'),		'00ffff');
is(Color::Calc::light_hex		('red'),		'ff8080');

is(Color::Calc::get_html		('F00'),		'red');
is(Color::Calc::mix_html		('red','blue'),		'purple');

is(Color::Calc::blend_bw_html		('red'),		'#ff8080');
is(Color::Calc::blend_html		('red'), 		'gray');
is(Color::Calc::bw_html		('red'),		'#4d4d4d');
is(Color::Calc::contrast_bw_html	('red'),		'white');
is(Color::Calc::contrast_html		('red'),		'aqua');
is(Color::Calc::dark_html		('red'),		'maroon');
is(Color::Calc::gray_html		('red'),		'#4d4d4d');
is(Color::Calc::grey_html		('red'),		'#4d4d4d');
is(Color::Calc::invert_html		('red'),		'aqua');
is(Color::Calc::light_html		('red'),		'#ff8080');

SKIP: {
eval { require Graphics::ColorObject; };
skip "Graphics::ColorObject not installed", 12 if $@;

is(lc Color::Calc::get_object		('red')->as_RGBhex,		'ff0000');
is(lc Color::Calc::mix_object		('red','blue')->as_RGBhex,	'800080');

is(lc Color::Calc::blend_bw_object	('red')->as_RGBhex,		'ff8080');
is(lc Color::Calc::blend_object	('red')->as_RGBhex, 		'808080');
is(lc Color::Calc::bw_object		('red')->as_RGBhex,		'4d4d4d');
is(lc Color::Calc::contrast_bw_object	('red')->as_RGBhex,		'ffffff');
is(lc Color::Calc::contrast_object	('red')->as_RGBhex,		'00ffff');
is(lc Color::Calc::dark_object		('red')->as_RGBhex,		'800000');
is(lc Color::Calc::gray_object		('red')->as_RGBhex,		'4d4d4d');
is(lc Color::Calc::grey_object		('red')->as_RGBhex,		'4d4d4d');
is(lc Color::Calc::invert_object	('red')->as_RGBhex,		'00ffff');
is(lc Color::Calc::light_object	('red')->as_RGBhex,		'ff8080');
}

is(join(',',Color::Calc::get_tuple		('red')),		'0255,0,0');
is(join(',',Color::Calc::mix_tuple		('red','blue')),	'0128,0,0128');

is(join(',',Color::Calc::blend_bw_tuple	('red')),		'0255,0128,0128');
is(join(',',Color::Calc::blend_tuple		('red')), 		'0128,0128,0128');
is(join(',',Color::Calc::bw_tuple		('red')),		'77,77,77');
is(join(',',Color::Calc::contrast_bw_tuple	('red')),		'0255,0255,0255');
is(join(',',Color::Calc::contrast_tuple	('red')),		'0,0255,0255');
is(join(',',Color::Calc::dark_tuple		('red')),		'0128,0,0');
is(join(',',Color::Calc::gray_tuple		('red')),		'77,77,77');
is(join(',',Color::Calc::grey_tuple		('red')),		'77,77,77');
is(join(',',Color::Calc::invert_tuple		('red')),		'0,0255,0255');
is(join(',',Color::Calc::light_tuple		('red')),		'0255,0128,0128');
