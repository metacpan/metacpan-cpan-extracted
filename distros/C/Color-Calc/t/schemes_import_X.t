use Test::More tests => 2;
use Test::NoWarnings;
use Color::Calc('OutputFormat' => 'html' );
is(color_get	('green'),		'lime');
