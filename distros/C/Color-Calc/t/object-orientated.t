use Test::More tests => 49;
use Test::NoWarnings;
use Color::Calc();

my $cc = Color::Calc->new( 'OutputFormat' => 'hex' );
is($cc->get		('red'),		'ff0000');
is($cc->mix		('red','blue'),		'800080');

is($cc->blend_bw	('red'),		'ff8080');
is($cc->blend		('red'), 		'808080');
is($cc->bw		('red'),		'4d4d4d');
is($cc->contrast_bw	('red'),		'ffffff');
is($cc->contrast	('red'),		'00ffff');
is($cc->dark		('red'),		'800000');
is($cc->gray		('red'),		'4d4d4d');
is($cc->grey		('red'),		'4d4d4d');
is($cc->invert		('red'),		'00ffff');
is($cc->light		('red'),		'ff8080');

$cc = Color::Calc->new( 'OutputFormat' => 'html' );
is($cc->get		('F00'),		'red');
is($cc->mix		('red','blue'),		'purple');

is($cc->blend_bw	('red'),		'#ff8080');
is($cc->blend		('red'), 		'gray');
is($cc->bw		('red'),		'#4d4d4d');
is($cc->contrast_bw	('red'),		'white');
is($cc->contrast	('red'),		'aqua');
is($cc->dark		('red'),		'maroon');
is($cc->gray		('red'),		'#4d4d4d');
is($cc->grey		('red'),		'#4d4d4d');
is($cc->invert		('red'),		'aqua');
is($cc->light		('red'),		'#ff8080');

SKIP: {
eval { require Graphics::ColorObject; };
skip "Graphics::ColorObject not installed", 12 if $@;

$cc = Color::Calc->new( 'OutputFormat' => 'object' );

is(lc $cc->get		('red')->as_RGBhex,		'ff0000');
is(lc $cc->mix		('red','blue')->as_RGBhex,	'800080');

is(lc $cc->blend_bw	('red')->as_RGBhex,		'ff8080');
is(lc $cc->blend	('red')->as_RGBhex, 		'808080');
is(lc $cc->bw		('red')->as_RGBhex,		'4d4d4d');
is(lc $cc->contrast_bw	('red')->as_RGBhex,		'ffffff');
is(lc $cc->contrast	('red')->as_RGBhex,		'00ffff');
is(lc $cc->dark		('red')->as_RGBhex,		'800000');
is(lc $cc->gray		('red')->as_RGBhex,		'4d4d4d');
is(lc $cc->grey		('red')->as_RGBhex,		'4d4d4d');
is(lc $cc->invert	('red')->as_RGBhex,		'00ffff');
is(lc $cc->light	('red')->as_RGBhex,		'ff8080');
}

$cc = Color::Calc->new( 'OutputFormat' => 'tuple' );
is(join(',',$cc->get		('red')),		'0255,0,0');
is(join(',',$cc->mix		('red','blue')),	'0128,0,0128');

is(join(',',$cc->blend_bw	('red')),		'0255,0128,0128');
is(join(',',$cc->blend		('red')), 		'0128,0128,0128');
is(join(',',$cc->bw		('red')),		'77,77,77');
is(join(',',$cc->contrast_bw	('red')),		'0255,0255,0255');
is(join(',',$cc->contrast	('red')),		'0,0255,0255');
is(join(',',$cc->dark		('red')),		'0128,0,0');
is(join(',',$cc->gray		('red')),		'77,77,77');
is(join(',',$cc->grey		('red')),		'77,77,77');
is(join(',',$cc->invert		('red')),		'0,0255,0255');
is(join(',',$cc->light		('red')),		'0255,0128,0128');
