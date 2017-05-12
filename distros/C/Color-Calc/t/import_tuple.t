use Test::More tests => 14;
use Test::NoWarnings;
use Color::Calc( 'OutputFormat' => 'tuple' );

is(join(',',color_get		('red')),		'0255,0,0');
is(join(',',color 		('red')),		'0255,0,0');
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
