use Test::More tests => 16;
use Test::NoWarnings;

use Color::Calc( 'OutputFormat' => 'hex', 'ColorScheme' => 'WWW' );

is( color_opposite('black'),	'000000' );
is( color_opposite('white'),	'ffffff' );

is( color_opposite('008000'),	'800080' );
is( color_opposite('800000'),	'008080' );
is( color_opposite('000080'),	'808000' );

is( color_opposite('008080'),	'800000' );
is( color_opposite('800080'),	'008000' );
is( color_opposite('808000'),	'000080' );

is( color_opposite('22cc22'),	'cc22cc' );
is( color_opposite('cc2222'),	'22cccc' );
is( color_opposite('2222cc'),	'cccc22' );

is( color_opposite('66ffff'),	'ff6666' );
is( color_opposite('ff66ff'),	'66ff66' );
is( color_opposite('ffff66'),	'6666ff' );

is( color_opposite('#3247CF'),	'cfba32' );
