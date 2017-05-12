use Test::More tests => 9;
use Test::NoWarnings;
use Color::Calc();
my $cc = Color::Calc->new( 'OutputFormat' => 'hex' );

is($cc->mix		('F00','00F'),		'800080');
is($cc->mix		('#F00','#00F'),	'800080');
is($cc->mix		('FF0000','0000FF'),	'800080');
is($cc->mix		('#FF0000','#0000FF'),	'800080');
is($cc->mix		([255,0,0],[0,0,255]),	'800080');
is($cc->mix		('0255',0,0,0,0,255),	'800080');
is($cc->mix		(['0255',0,0],0,0,255),	'800080');
is($cc->mix		('0255',0,0,[0,0,255]),	'800080');
