use Test::More tests => 14;
use Test::NoWarnings;

use Color::Calc( 'OutputFormat' => 'hex', 'ColorScheme' => 'WWW' );

is( color_round('black'),	'000000' );
is( color_round('white'),	'ffffff' );

is( color_round('green'),	'009900' );
is( color_round('maroon'),	'990000' );
is( color_round('silver'),	'cccccc' );

is( color_round('#c6c6c6'),	'cccccc' );
is( color_round('#c7c7c7'),	'cccccc' );

is( color_round('#222222'),	'333333' );
is( color_round('#808080'),	'999999' );
is( color_round('#DDDDDD'),	'cccccc' );

is( color_round('#AABBEE'),	'99ccff' );
is( color_round('#08FC23'),	'00ff33' );
is( color_round('#3247CF'),	'3333cc' );
