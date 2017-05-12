use Test::More tests => 14;
use Test::NoWarnings;

use Color::Calc( 'OutputFormat' => 'hex', 'ColorScheme' => 'WWW' );

is( color_safe('black'),	'000000' );
is( color_safe('white'),	'ffffff' );

is( color_safe('green'),	'008000' );
is( color_safe('maroon'),	'800000' );
is( color_safe('silver'),	'c0c0c0' );

is( color_safe('#c6c6c6'),	'c0c0c0' );
is( color_safe('#c7c7c7'),	'cccccc' );

is( color_safe('#222222'),	'333333' );
is( color_safe('#8F807F'),	'808080' );
is( color_safe('#808080'),	'808080' );

is( color_safe('#AABBEE'),	'99ccff' );
is( color_safe('#08FC23'),	'00ff33' );
is( color_safe('#3247CF'),	'3333cc' );
