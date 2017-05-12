use Test::More tests => 9;
use Test::NoWarnings;
use Color::Calc( 'OutputFormat' => 'hex' );

is(color_mix		('F00','00F'),		'800080');
is(color_mix		('#F00','#00F'),	'800080');
is(color_mix		('FF0000','0000FF'),	'800080');
is(color_mix		('#FF0000','#0000FF'),	'800080');
is(color_mix		([255,0,0],[0,0,255]),	'800080');
is(color_mix		('0255',0,0,0,0,255),	'800080');
is(color_mix		(['0255',0,0],0,0,255),	'800080');
is(color_mix		('0255',0,0,[0,0,255]),	'800080');
