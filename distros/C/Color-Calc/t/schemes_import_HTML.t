use Test::More tests => 2;
use Test::NoWarnings;
use Color::Calc('ColorScheme' => 'HTML', 'OutputFormat' => 'html');
is(color_get	('green'),		'green');
