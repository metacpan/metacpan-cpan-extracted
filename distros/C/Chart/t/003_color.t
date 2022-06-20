#!/usr/bin/perl
#
use v5.12;
use warnings;
use Test::More tests => 303;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Chart::Color';
eval "use $module";
is( not( $@), 1, 'could load the module');


warning_like {Chart::Color->new()}                    {carped => qr/constructor of/},  "need argument to create object";
warning_like {Chart::Color->new('weirdcolorname')}    {carped => qr/unknown color/},   "accept only known color names";
warning_like {Chart::Color->new('CHIMNEY:red')}       {carped => qr/ not installed/},  "accept only known palletes";
warning_like {Chart::Color->new('#23232')       }     {carped => qr/hex color definition/},  "hex definition too short";
warning_like {Chart::Color->new('#232321f')     }     {carped => qr/hex color definition/},  "hex definition too long";
warning_like {Chart::Color->new('#23232g')       }    {carped => qr/hex color definition/},    "hex definition has forbidden chars";
warning_like {Chart::Color->new('#2322%E')       }    {carped => qr/hex color definition/},    "hex definition has forbidden chars";
warning_like {Chart::Color->new(1,1)}                 {carped => qr/constructor of/},  "too few positional args";
warning_like {Chart::Color->new(1,1,1,1)}             {carped => qr/constructor of/},  "too many positional args";
warning_like {Chart::Color->new([1,1])}               {carped => qr/need exactly 3/},  "too few positional args in ref";
warning_like {Chart::Color->new([1,1,1,1])}           {carped => qr/need exactly 3/},  "too many positional args in ref";
warning_like {Chart::Color->new({ r=>1, g=>1})}       {carped => qr/constructor of/},  "too few named args in ref";
warning_like {Chart::Color->new({r=>1,g=>1,b=>1,h=>1,})} {carped => qr/constructor of/},"too many name args in ref";
warning_like {Chart::Color->new( r=>1, g=>1)}         {carped => qr/constructor of/},  "too few named args";
warning_like {Chart::Color->new(r=>1,g=>1,b=>1,h=>1)} {carped => qr/constructor of/},  "too many name args";
warning_like {Chart::Color->new(r=>1,g=>1,h=>1)}      {carped => qr/argument keys/},   "don't mix named args";
warning_like {Chart::Color->new(r=>1,g=>1,t=>1)}      {carped => qr/argument keys/},   "don't invent named args";

my $red = Chart::Color->new('red');
is( ref $red,        $module, 'could create object by name');
is( $red->red,           255, 'named red has correct red component value');
is( $red->green,           0, 'named red has correct green component value');
is( $red->blue,            0, 'named red has correct blue component value');
is( $red->hue,             0, 'named red has correct hue component value');
is( $red->saturation,    100, 'named red has correct saturation component value');
is( $red->lightness,      50, 'named red has correct lightness component value');
is( $red->name,        'red', 'named red has correct name');
is( $red->rgb_hex, '#ff0000', 'named red has correct hex value');
is(($red->rgb)[0],       255, 'named red has correct rgb red component value');
is(($red->rgb)[1],         0, 'named red has correct rgb green component value');
is(($red->rgb)[2],         0, 'named red has correct rgb blue component value');
is(($red->hsl)[0],         0, 'named red has correct hsl hue component value');
is(($red->hsl)[1],       100, 'named red has correct hsl saturation component value');
is(($red->hsl)[2],        50, 'named red has correct hsl lightness component value');
is( $red->string,      'red', 'named red does stringify correctly');
is( Chart::Color->new(15,12,13)->string, '[ 15, 12, 13 ]', 'random color does stringify correctly');


$red = Chart::Color->new('#FF0000');
is( ref $red,     $module, 'could create object by hex value');
is( $red->red,           255, 'hex red has correct red component value');
is( $red->green,           0, 'hex red has correct green component value');
is( $red->blue,            0, 'hex red has correct blue component value');
is( $red->hue,             0, 'hex red has correct hue component value');
is( $red->saturation,    100, 'hex red has correct saturation component value');
is( $red->lightness,      50, 'hex red has correct lightness component value');
is( $red->name,        'red', 'hex red has correct name');
is( $red->rgb_hex, '#ff0000', 'hex red has correct hex value');
is(($red->rgb)[0],       255, 'hex red has correct rgb red component value');
is(($red->rgb)[1],         0, 'hex red has correct rgb green component value');
is(($red->rgb)[2],         0, 'hex red has correct rgb blue component value');
is(($red->hsl)[0],         0, 'hex red has correct hsl hue component value');
is(($red->hsl)[1],       100, 'hex red has correct hsl saturation component value');
is(($red->hsl)[2],        50, 'hex red has correct hsl lightness component value');

$red = Chart::Color->new('#f00');
is( ref $red,     $module, 'could create object by short hex value');
is( $red->name,        'red', 'short hex red has correct name');

$red = Chart::Color->new(255, 0, 0);
is( ref $red, $module, 'could create object by positional RGB');
is( $red->red,           255, 'positional red has correct red component value');
is( $red->green,           0, 'positional red has correct green component value');
is( $red->blue,            0, 'positional red has correct blue component value');
is( $red->hue,             0, 'positional red has correct hue component value');
is( $red->saturation,    100, 'positional red has correct saturation component value');
is( $red->lightness,      50, 'positional red has correct lightness component value');
is( $red->name,        'red', 'positional red has correct name');
is( $red->rgb_hex, '#ff0000', 'positional red has correct hex value');
is(($red->rgb)[0],       255, 'positional red has correct rgb red component value');
is(($red->rgb)[1],         0, 'positional red has correct rgb green component value');
is(($red->rgb)[2],         0, 'positional red has correct rgb blue component value');
is(($red->hsl)[0],         0, 'positional red has correct hsl hue component value');
is(($red->hsl)[1],       100, 'positional red has correct hsl saturation component value');
is(($red->hsl)[2],        50, 'positional red has correct hsl lightness component value');

$red = Chart::Color->new([255, 0, 0]);
is( ref $red, $module, 'could create object by RGB array ref');
is( $red->red,           255, 'array ref red has correct red component value');
is( $red->green,           0, 'array ref red has correct green component value');
is( $red->blue,            0, 'array ref red has correct blue component value');
is( $red->hue,             0, 'array ref red has correct hue component value');
is( $red->saturation,    100, 'array ref red has correct saturation component value');
is( $red->lightness,      50, 'array ref red has correct lightness component value');
is( $red->name,        'red', 'array ref red has correct name');
is( $red->rgb_hex, '#ff0000', 'array ref red has correct hex value');
is(($red->rgb)[0],       255, 'array ref red has correct rgb red component value');
is(($red->rgb)[1],         0, 'array ref red has correct rgb green component value');
is(($red->rgb)[2],         0, 'array ref red has correct rgb blue component value');
is(($red->hsl)[0],         0, 'array ref red has correct hsl hue component value');
is(($red->hsl)[1],       100, 'array ref red has correct hsl saturation component value');
is(($red->hsl)[2],        50, 'array ref red has correct hsl lightness component value');

$red = Chart::Color->new(r => 255, g => 0, b => 0);
is( ref $red, $module, 'could create object by RGB named args');
is( $red->red,           255, 'named arg red has correct red component value');
is( $red->green,           0, 'named arg red has correct green component value');
is( $red->blue,            0, 'named arg red has correct blue component value');
is( $red->hue,             0, 'named arg red has correct hue component value');
is( $red->saturation,    100, 'named arg red has correct saturation component value');
is( $red->lightness,      50, 'named arg red has correct lightness component value');
is( $red->name,        'red', 'named arg red has correct name');
is( $red->rgb_hex, '#ff0000', 'named arg red has correct hex value');
is(($red->rgb)[0],       255, 'named arg red has correct rgb red component value');
is(($red->rgb)[1],         0, 'named arg red has correct rgb green component value');
is(($red->rgb)[2],         0, 'named arg red has correct rgb blue component value');
is(($red->hsl)[0],         0, 'named arg red has correct hsl hue component value');
is(($red->hsl)[1],       100, 'named arg red has correct hsl saturation component value');
is(($red->hsl)[2],        50, 'named arg red has correct hsl lightness component value');

$red = Chart::Color->new({Red => 255, Green => 0, Blue => 0 });
is( ref $red, $module, 'could create object by RGB hash ref');
is( $red->red,           255, 'hash ref red has correct red component value');
is( $red->green,           0, 'hash ref red has correct green component value');
is( $red->blue,            0, 'hash ref red has correct blue component value');
is( $red->hue,             0, 'hash ref red has correct hue component value');
is( $red->saturation,    100, 'hash ref red has correct saturation component value');
is( $red->lightness,      50, 'hash ref red has correct lightness component value');
is( $red->name,        'red', 'hash ref red has correct name');
is( $red->rgb_hex, '#ff0000', 'hash ref red has correct hex value');
is(($red->rgb)[0],       255, 'hash ref red has correct rgb red component value');
is(($red->rgb)[1],         0, 'hash ref red has correct rgb green component value');
is(($red->rgb)[2],         0, 'hash ref red has correct rgb blue component value');
is(($red->hsl)[0],         0, 'hash ref red has correct hsl hue component value');
is(($red->hsl)[1],       100, 'hash ref red has correct hsl saturation component value');
is(($red->hsl)[2],        50, 'hash ref red has correct hsl lightness component value');

$red = Chart::Color->new({h => 0, s => 100, l => 50 });
is( ref $red, $module, 'could create object by HSL hash ref');
is( $red->red,           255, 'hash ref red has correct red component value');
is( $red->green,           0, 'hash ref red has correct green component value');
is( $red->blue,            0, 'hash ref red has correct blue component value');
is( $red->hue,             0, 'hash ref red has correct hue component value');
is( $red->saturation,    100, 'hash ref red has correct saturation component value');
is( $red->lightness,      50, 'hash ref red has correct lightness component value');
is( $red->name,        'red', 'hash ref red has correct name');
is( $red->rgb_hex, '#ff0000', 'hash ref red has correct hex value');
is(($red->rgb)[0],       255, 'hash ref red has correct rgb red component value');
is(($red->rgb)[1],         0, 'hash ref red has correct rgb green component value');
is(($red->rgb)[2],         0, 'hash ref red has correct rgb blue component value');
is(($red->hsl)[0],         0, 'hash ref red has correct hsl hue component value');
is(($red->hsl)[1],       100, 'hash ref red has correct hsl saturation component value');
is(($red->hsl)[2],        50, 'hash ref red has correct hsl lightness component value');

$red = Chart::Color->new( Hue => 0, Sat => 100, Light => 50 );
is( ref $red, $module, 'could create object by HSL named args');
is( $red->red,           255, 'hash ref red has correct red component value');
is( $red->green,           0, 'hash ref red has correct green component value');
is( $red->blue,            0, 'hash ref red has correct blue component value');
is( $red->hue,             0, 'hash ref red has correct hue component value');
is( $red->saturation,    100, 'hash ref red has correct saturation component value');
is( $red->lightness,      50, 'hash ref red has correct lightness component value');
is( $red->name,        'red', 'hash ref red has correct name');
is( $red->rgb_hex, '#ff0000', 'hash ref red has correct hex value');
is(($red->rgb)[0],       255, 'hash ref red has correct rgb red component value');
is(($red->rgb)[1],         0, 'hash ref red has correct rgb green component value');
is(($red->rgb)[2],         0, 'hash ref red has correct rgb blue component value');
is(($red->hsl)[0],         0, 'hash ref red has correct hsl hue component value');
is(($red->hsl)[1],       100, 'hash ref red has correct hsl saturation component value');
is(($red->hsl)[2],        50, 'hash ref red has correct hsl lightness component value');


my $c = Chart::Color->new( 1,2,3 );
is( ref $red, $module, 'could create object by random unnamed color');
is( $c->red,           1, 'random color has correct red component value');
is( $c->green,         2, 'random color has correct green component value');
is( $c->blue,          3, 'random color has correct blue component value');
is( $c->name,         '', 'random color has no name');

my $blue = Chart::Color->new( 'blue' );
is( $blue->red,        0, 'blue has correct red component value');
is( $blue->green,      0, 'blue has correct green component value');
is( $blue->blue,     255, 'blue has correct blue component value');
is( $blue->hue,      240, 'blue has correct hue component value');
is( $blue->saturation,100,'blue has correct saturation component value');
is( $blue->lightness,  50,'blue has correct lightness component value');
is( $blue->name,  'blue', 'blue color has correct name');

is( $blue->distance_to($red),            120, 'correct default hsl distance between red and blue');
is( $blue->distance_to($red, 'HSL'),     120, 'correct hsl distance between red and blue');
is( $blue->distance_to($red, 'Hue'),     120, 'correct hue distance between red and blue, long name');
is( $blue->distance_to($red, 'h'),       120, 'correct hue distance between red and blue');
is( $blue->distance_to($red, 's'),         0, 'correct sturation distance between red and blue');
is( $blue->distance_to($red, 'Sat'),       0, 'correct sturation distance between red and blue, long name');
is( $blue->distance_to($red, 'l'),         0, 'correct lightness distance between red and blue');
is( $blue->distance_to($red, 'Light'),     0, 'correct lightness distance between red and blue, long name');
is( $blue->distance_to($red, 'hs'),      120, 'correct hs distance between red and blue');
is( $blue->distance_to($red, 'hl'),      120, 'correct hl distance between red and blue');
is( $blue->distance_to($red, 'sl'),        0, 'correct sl distance between red and blue');
is( int $blue->distance_to($red, 'rgb'), 360, 'correct rgb distance between red and blue');
is( $blue->distance_to($red, 'Red'),     255, 'correct red distance between red and blue, long name');
is( $blue->distance_to($red, 'r'),       255, 'correct red distance between red and blue');
is( $blue->distance_to($red, 'Green'),     0, 'correct green distance between red and blue, long name');
is( $blue->distance_to($red, 'g'),         0, 'correct green distance between red and blue');
is( $blue->distance_to($red, 'Blue'),    255, 'correct blue distance between red and blue, long name');
is( $blue->distance_to($red, 'b'),       255, 'correct blue distance between red and blue');
is( $blue->distance_to($red, 'rg'),      255, 'correct rg distance between red and blue');
is( int $blue->distance_to($red, 'rb'),  360, 'correct rb distance between red and blue');
is( $blue->distance_to($red, 'gb'),      255, 'correct gb distance between red and blue');

is( int $blue->distance_to([10, 10, 245],      ),   8, 'correct default hsl  distance between own rgb blue and blue');
is( int $blue->distance_to([10, 10, 245], 'HSL'),   8, 'correct hsl distance between own rgb blue and blue');
is(     $blue->distance_to([10, 10, 245], 'Hue'),   0, 'correct hue distance between own rgb blue and blue, long name');
is(     $blue->distance_to([10, 10, 245], 'h'),     0, 'correct hue distance between own rgb blue and blue');
is( int $blue->distance_to([10, 10, 245], 's'),     8, 'correct sturation distance between own rgb blue and blue');
is( int $blue->distance_to([10, 10, 245], 'Sat'),   8, 'correct sturation distance between own rgb blue and blue, long name');
is( int $blue->distance_to([10, 10, 245], 'l'),     0, 'correct lightness distance between own rgb blue and blue');
is( int $blue->distance_to([10, 10, 245], 'Light'), 0, 'correct lightness distance between own rgb blue and blue, long name');
is( int $blue->distance_to([10, 10, 245], 'hs'),    8, 'correct hs distance between own rgb blue and blue');
is( int $blue->distance_to([10, 10, 245], 'hl'),    0, 'correct hl distance between own rgb blue and blue');
is( int $blue->distance_to([10, 10, 245], 'sl'),    8, 'correct sl distance between own rgb blue and blue');
is( int $blue->distance_to([10, 10, 245], 'rgb'),  17, 'correct rgb distance between own rgb blue and blue');
is(     $blue->distance_to([10, 10, 245], 'Red'),  10, 'correct red distance between own rgb blue and blue, long name');
is(     $blue->distance_to([10, 10, 245], 'r'),    10, 'correct red distance between own rgb blue and blue');
is(     $blue->distance_to([10, 10, 245], 'Green'),10, 'correct green distance between own rgb blue and blue, long name');
is(     $blue->distance_to([10, 10, 245], 'g'),    10, 'correct green distance between own rgb blue and blue');
is(     $blue->distance_to([10, 10, 245], 'Blue'), 10, 'correct blue distance between own rgb blue and blue, long name');
is(     $blue->distance_to([10, 10, 245], 'b'),    10, 'correct blue distance between own rgb blue and blue');
is( int $blue->distance_to([10, 10, 245], 'rg'),   14, 'correct rg distance between own rgb blue and blue');
is( int $blue->distance_to([10, 10, 245], 'rb'),   14, 'correct rb distance between own rgb blue and blue');
is( int $blue->distance_to([10, 10, 245], 'gb'),   14, 'correct gb distance between own rgb blue and blue');

is( int $blue->distance_to({h =>230, s => 90, l=>40}),         17, 'correct default hsl distance between own hsl blue and blue');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'HSL'),  17, 'correct hsl distance between own hsl blue and blue');
is(     $blue->distance_to({h =>230, s => 90, l=>40}, 'Hue'),  10, 'correct hue distance between own hsl blue and blue, long name');
is(     $blue->distance_to({h =>230, s => 90, l=>40}, 'h'),    10, 'correct hue distance between own hsl blue and blue');
is(     $blue->distance_to({h =>230, s => 90, l=>40}, 's'),    10, 'correct sturation distance between own hsl blue and blue');
is(     $blue->distance_to({h =>230, s => 90, l=>40}, 'Sat'),  10, 'correct sturation distance between own hsl blue and blue, long name');
is(     $blue->distance_to({h =>230, s => 90, l=>40}, 'l'),    10, 'correct lightness distance between own hsl blue and blue');
is(     $blue->distance_to({h =>230, s => 90, l=>40}, 'Light'),10, 'correct lightness distance between own hsl blue and blue, long name');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'hs'),   14, 'correct hs distance between own hsl blue and blue');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'hl'),   14, 'correct hl distance between own hsl blue and blue');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'sl'),   14, 'correct sl distance between own hsl blue and blue');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'rgb'),  74, 'correct rgb distance between own hsl blue and blue');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'Red'),  10, 'correct red distance between own hsl blue and blue, long name');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'r'),    10, 'correct red distance between own hsl blue and blue');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'Green'),41, 'correct green distance between own hsl blue and blue, long name');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'g'),    41, 'correct green distance between own hsl blue and blue');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'Blue'), 61, 'correct blue distance between own hsl blue and blue, long name');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'b'),    61, 'correct blue distance between own hsl blue and blue');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'rg'),   42, 'correct rg distance between own hsl blue and blue');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'rb'),   61, 'correct rb distance between own hsl blue and blue');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'gb'),   73, 'correct gb distance between own hsl blue and blue');

$red = Chart::Color->new('#FF0000');
warning_like {$red->add()}                    {carped => qr/argument options/},    "need argument to add to color object";
warning_like {$red->add('weirdcolorname')}    {carped => qr/unknown color/},       "accept only known color names";
warning_like {$red->add('#23232')       }     {carped => qr/hex color definition/}, "hex definition too short";
warning_like {$red->add('#232321f')     }     {carped => qr/hex color definition/}, "hex definition too long";
warning_like {$red->add(1,1)}                 {carped => qr/argument options/},     "too few positional args";
warning_like {$red->add(1,1,1,1)}             {carped => qr/wrong number/},         "too many positional args";
warning_like {$red->add([1,1])}               {carped => qr/ 3 numerical values/},  "too few positional args in ref";
warning_like {$red->add([1,1,1,1])}           {carped => qr/ 3 numerical values/},  "too many positional args in ref";
warning_like {$red->add(r=>1,g=>1,t=>1)}      {carped => qr/unknown hash key/},   "don't invent named args";
warning_like {$red->add({r=>1,g=>1,t=>1})}    {carped => qr/unknown hash key/},   "don't invent named args, in ref";

my $white = Chart::Color->new('white');
my $black = Chart::Color->new('black');

is( $white->add( 255, 255, 255 )->name,              'white',   "it can't get whiter than white with additive color adding");
is( $white->add( {Hue => 10} )->name,                'white',   "hue doesnt change when were on level white");
is( $white->add( {Red => 10} )->name,                'white',   "hue doesnt change when adding red on white");
is( $white->add( $white )->name,                     'white',   "adding white on white is still white");
is( $red->add( $black )->name,                         'red',   "red + black = red");
is( $red->add( $black, -1 )->name,                     'red',   "red - black = red");
is( $white->add( $red, -1 )->name,                    'aqua',   "white - red = aqua");
is( $white->add( $white, -0.5 )->name,                'gray',   "white - 0.5 white = grey");
is( Chart::Color->new(1,2,3)->add( 2,1,0)->name,     'gray1',   "adding positional args"); # = 3, 3, 3
is( $red->add( {Saturation => -10} )->red,               242,   "paling red 10%, red value");
is( $red->add( {Saturation => -10} )->blue,               13,   "paling red 10%, blue value");
is( $white->add( {Lightness => -12} )->name,        'gray88',   "dimming white 12%");
is( $black->add( {Red => 255} )->name,                 'red',   "creating pure red from black");
is( $black->add( {Green => 255} )->name,              'lime',   "creating pure green from black");
is( $black->add( {  b => 255} )->name,                'blue',   "creating pure blue from black with short name");


warning_like {$red->blend_with()}                    {carped => qr/color object/},    "need argument to blend to color object";
warning_like {$red->blend_with('weirdcolorname')}    {carped => qr/unknown color/},   "accept only known color names";
warning_like {$red->blend_with('#23232')       }     {carped => qr/hex color definition/},  "hex definition too short";
warning_like {$red->blend_with('#232321f')     }     {carped => qr/hex color definition/},  "hex definition too long";
warning_like {$red->blend_with([1,1])}               {carped => qr/need exactly 3/},  "too few positional args in ref";
warning_like {$red->blend_with([1,1,1,1])}           {carped => qr/need exactly 3/},  "too many positional args in ref";
warning_like {$red->blend_with({r=>1,g=>1,t=>1})}    {carped => qr/argument keys/},   "don't mix named args, in hash ref color def";
warning_like {$red->blend_with({r=>1,g=>1,l=>1})}    {carped => qr/argument keys/},   "don't invent named args, in hash ref color def";

is( $black->blend_with( $white )->name,                  'gray',   "blend black + white = gray");
is( $black->blend_with( $white, 0 )->name,              'black',   "blend nothing, keep color");
is( $black->blend_with( $white, 1 )->name,              'white',   "blend nothing, take c2");
is( $black->blend_with( $white, 2 )->name,              'white',   "RGB limits kept");
is( $red->blend_with( 'blue')->name,                  'fuchsia',   "blending with name");
is( $red->blend_with( '#0000ff')->name,               'fuchsia',   "blending with hex def");
is( $red->blend_with( [0,0,255])->name,               'fuchsia',   "blending with array ref color def");
is( $red->blend_with({R=> 0, G=> 0, B=>255})->name,   'fuchsia',   "blending with RGB hash ref color def");
is( $red->blend_with({H=> 240, S=> 100, L=>50})->name,'fuchsia',   "blending with HSL hash ref color def");

is( $black->gradient_to( $white, 1 )->name,             'black',   'shortest gradient is $self');
my @g = $black->gradient_to( $white, 2 );
is( int @g,                                                2,   'gradient with length 2 has only boundary cases');
is( $g[0]->name,                                     'black',   'gradient with length 2 starts on left boundary');
is( $g[1]->name,                                     'white',   'gradient with length 2 ends on right boundary');
@g = $black->gradient_to( $white, 6 );
is( int @g,                                                6,   'gradient has right length = 6');
is( $g[1]->name,                                     'gray20',  'grey20 is between black and white');
is( $g[2]->name,                                     'gray40',  'grey40 is between black and white');
@g = $black->gradient_to( $white, 3, 2 );
is( int @g,                                                3,   'gradient has right length = 3');
is( $g[1]->name,                                     'gray25',  'grey25 is between black and white in none linear gradient');
@g = $black->gradient_to( $white, 3, .41 );
is( $g[1]->name,                                     'gray75',  'grey75 is between black and white in none linear gradient');
@g = $red->gradient_to( '#0000FF', 3 );
is( $g[1]->name,                                    'fuchsia',  'fuchsia is between red and blue in linear gradient');

@g = $black->complementary();
is( int @g,                                                 1,   "default is one complementary color");
is( $black->complementary()->name,                    'black',   "black has no complementary color");
is( $white->complementary()->name,                    'white',   "white has no complementary color");
is( $red->complementary()->name,                       'aqua',   "aqua is complementary to red");

@g = $red->complementary(3);
is( int @g,                                                 3,   "requested amount of complementary colors");
is( $g[0]->saturation,                      $g[1]->saturation,   "saturation is equal on complementary circle");
is( $g[1]->saturation,                      $g[2]->saturation,   "saturation is equal on complementary circle 2");
is( $g[0]->lightness,                        $g[1]->lightness,   "lightness is equal on complementary circle");
is( $g[1]->lightness,                        $g[2]->lightness,   "lightness is equal on complementary circle 2");
is( $g[0]->name,                                        'red',   "complementary circle starts with C1");
is( $g[1]->name,                                       'lime',   "complementary gos on to green");
is( $g[2]->name,                                       'blue',   "complementary circle ends with blue");

@g = Chart::Color->new(15,12,13)->complementary(3);
is( $g[0]->saturation,                      $g[1]->saturation,   "saturation is equal on complementary circle of random color");
is( $g[1]->saturation,                      $g[2]->saturation,   "saturation is equal on complementary circle 2");
is( $g[0]->lightness,                        $g[1]->lightness,   "lightness is equal on complementary circle of random color");
is( $g[1]->lightness,                        $g[2]->lightness,   "lightness is equal on complementary circle 2");

@g = Chart::Color->new(15,12,13)->complementary(4, 12, 20);
is( int @g,                                                 4,   "requested amount of complementary colors");
is( $g[1]->saturation,                      $g[3]->saturation,   "saturation is equal on opposing sides of skewed circle");
is( $g[1]->lightness,                        $g[3]->lightness,   "lightness is equal on opposing sides of skewed circle");
is( $g[1]->saturation-6,                    $g[0]->saturation,   "saturation moves on skewed circle as predicted fore ");
is( $g[1]->saturation+6,                    $g[2]->saturation,   "saturation moves on skewed circle as predicted back");
is( $g[1]->lightness-10,                     $g[0]->lightness,   "lightness moves on skewed circle as predicted fore");
is( $g[1]->lightness+10,                     $g[2]->lightness,   "lightness moves on skewed circle as predicted back");

@g = Chart::Color->new(15,12,13)->complementary(4, 512, 520);
is( abs($g[0]->saturation-$g[2]->saturation) < 100,         1,   "cut too large saturnation skews");
is( abs($g[0]->lightness-$g[2]->lightness) < 100,           1,   "cut too large lightness skews");

@g = Chart::Color->new(15,12,13)->complementary(5, 10, 20);
is( $g[1]->saturation,                      $g[4]->saturation,   "saturation is equal on opposing sides of odd and skewed circle 1");
is( $g[2]->saturation,                      $g[3]->saturation,   "saturation is equal on opposing sides of odd and skewed circle 2");
is( $g[1]->lightness,                        $g[4]->lightness,   "lightness is equal on opposing sides of odd and skewed circle 1");
is( $g[2]->lightness,                        $g[3]->lightness,   "lightness is equal on opposing sides of odd and skewed circle 2");
is( $g[1]->saturation-4,                    $g[0]->saturation,   "saturation moves on odd and skewed circle as predicted fore ");
is( $g[1]->saturation+4,                    $g[2]->saturation,   "saturation moves on odd and skewed circle as predicted back");
is( $g[1]->lightness -8,                     $g[0]->lightness,   "lightness moves on odd and skewed circle as predicted fore");
is( $g[1]->lightness +8,                     $g[2]->lightness,   "lightness moves on odd and skewed circle as predicted back");


exit 0;
