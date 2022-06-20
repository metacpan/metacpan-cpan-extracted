#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 108;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Chart::Color::Value';

eval "use $module";
is( not($@), 1, 'could load the module');

my $chk_rgb        = \&Chart::Color::Value::check_rgb;
my $chk_hsl        = \&Chart::Color::Value::check_hsl;
my $tr_rgb         = \&Chart::Color::Value::trim_rgb;
my $tr_hsl         = \&Chart::Color::Value::trim_hsl;
my $d_rgb          = \&Chart::Color::Value::distance_rgb;
my $d_hsl          = \&Chart::Color::Value::distance_hsl;
my $rgb2h          = \&Chart::Color::Value::hex_from_rgb;


ok( !$chk_rgb->(0,0,0),       'check rgb values works on lower bound values');
ok( !$chk_rgb->(255,255,255), 'check rgb values works on upper bound values');
warning_like {$chk_rgb->(0,0)}       {carped => qr/exactly 3/},   "check rgb got too few values";
warning_like {$chk_rgb->(0,0,0,0)}   {carped => qr/exactly 3/},   "check rgb got too many  values";
warning_like {$chk_rgb->(-1, 0,0)}   {carped => qr/red value/},   "red value is too small";
warning_like {$chk_rgb->(0.5, 0,0)}  {carped => qr/red value/},   "red value is not integer";
warning_like {$chk_rgb->(256, 0,0)}  {carped => qr/red value/},   "red value is too big";
warning_like {$chk_rgb->(0, -1, 0)}  {carped => qr/green value/}, "green value is too small";
warning_like {$chk_rgb->(0, 0.5, 0)} {carped => qr/green value/}, "green value is not integer";
warning_like {$chk_rgb->(0, 256,0)}  {carped => qr/green value/}, "green value is too big";
warning_like {$chk_rgb->(0,0, -1 )}  {carped => qr/blue value/},  "blue value is too small";
warning_like {$chk_rgb->(0,0, 0.5 )} {carped => qr/blue value/},  "blue value is not integer";
warning_like {$chk_rgb->(0,0, 256)}  {carped => qr/blue value/},  "blue value is too big";

ok( !$chk_hsl->(0,0,0),       'check hsl values works on lower bound values');
ok( !$chk_hsl->(359,100,100), 'check hsl values works on upper bound values');
warning_like {$chk_hsl->(0,0)}       {carped => qr/exactly 3/},   "check rgb got too few values";
warning_like {$chk_hsl->(0,0,0,0)}   {carped => qr/exactly 3/},   "check rgb got too many  values";
warning_like {$chk_hsl->(-1, 0,0)}   {carped => qr/hue value/},   "hue value is too small";
warning_like {$chk_hsl->(0.5, 0,0)}  {carped => qr/hue value/},   "hue value is not integer";
warning_like {$chk_hsl->(360, 0,0)}  {carped => qr/hue value/},   "hue value is too big";
warning_like {$chk_hsl->(0, -1, 0)}  {carped => qr/saturation value/}, "saturation value is too small";
warning_like {$chk_hsl->(0, 0.5, 0)} {carped => qr/saturation value/}, "saturation value is not integer";
warning_like {$chk_hsl->(0, 101,0)}  {carped => qr/saturation value/}, "saturation value is too big";
warning_like {$chk_hsl->(0,0, -1 )}  {carped => qr/lightness value/},  "lightness value is too small";
warning_like {$chk_hsl->(0,0, 0.5 )} {carped => qr/lightness value/},  "lightness value is not integer";
warning_like {$chk_hsl->(0,0, 101)}  {carped => qr/lightness value/},  "lightness value is too big";



my @rgb = $tr_rgb->();
is( int @rgb,  3,     'default color is set');
is( $rgb[0],   0,     'default color is black (R) no args');
is( $rgb[1],   0,     'default color is black (G) no args');
is( $rgb[2],   0,     'default color is black (B) no args');
@rgb = $tr_rgb->(1,2);
is( $rgb[0],   0,     'default color is black (R) too few args');
is( $rgb[1],   0,     'default color is black (G) too few args');
is( $rgb[2],   0,     'default color is black (B) too few args');
@rgb = $tr_rgb->(1,2,3,4);
is( $rgb[0],   0,     'default color is black (R) too many args');
is( $rgb[1],   0,     'default color is black (G) too many args');
is( $rgb[2],   0,     'default color is black (B) too many args');
@rgb = $tr_rgb->(-1,-1,-1);
is( int @rgb,  3,     'color is trimmed up');
is( $rgb[0],   0,     'too low red value is trimmed up');
is( $rgb[1],   0,     'too low green value is trimmed up');
is( $rgb[2],   0,     'too low blue value is trimmed up');
@rgb = $tr_rgb->(256, 256, 256);
is( int @rgb,  3,     'color is trimmed up');
is( $rgb[0], 255,     'too high red value is trimmed down');
is( $rgb[1], 255,     'too high green value is trimmed down');
is( $rgb[2], 255,     'too high blue value is trimmed down');

my @hsl = $tr_hsl->();
is( int @hsl,  3,     'default color is set');
is( $hsl[0],   0,     'default color is black (H) no args');
is( $hsl[1],   0,     'default color is black (S) no args');
is( $hsl[2],   0,     'default color is black (L) no args');
@hsl = $tr_hsl->(1,2);
is( $hsl[0],   0,     'default color is black (H) too few args');
is( $hsl[1],   0,     'default color is black (S) too few args');
is( $hsl[2],   0,     'default color is black (L) too few args');
@hsl = $tr_hsl->(1,2,3,4);
is( $hsl[0],   0,     'default color is black (H) too many args');
is( $hsl[1],   0,     'default color is black (S) too many args');
is( $hsl[2],   0,     'default color is black (L) too many args');;
@hsl = $tr_hsl->(-1,-1,-1);
is( int @rgb,  3,     'color is trimmed up');
is( $hsl[0], 359,     'too low hue value is rotated up');
is( $hsl[1],   0,     'too low green value is trimmed up');
is( $hsl[2],   0,     'too low blue value is trimmed up');
@hsl = $tr_hsl->(360, 101, 101);
is( int @rgb,  3,     'color is trimmed up');
is( $hsl[0],   0,     'too high hue value is rotated down');
is( $hsl[1], 100,     'too high saturation value is trimmed down');
is( $hsl[2], 100,     'too high lightness value is trimmed down');


warning_like {Chart::Color::Value::hsl_from_rgb(1,1,1,1)} {carped => qr/3 positive integer/},
                                                      "need 3 values rgb to convert color from rgb to hsl";
warning_like {Chart::Color::Value::hsl_from_rgb(1,1)} {carped => qr/3 positive integer/},
                                                      "need 3 values rgb to convert color from rgb to hsl";
warning_like {Chart::Color::Value::hsl_from_rgb(1,1,-1)} {carped => qr/blue value/},
                                                      "blue value is too small for conversion";
warning_like {Chart::Color::Value::hsl_from_rgb(256,1,0)} {carped => qr/red value/},
                                                      "red value is too large for conversion";
warning_like {Chart::Color::Value::rgb_from_hsl(1,1)} {carped => qr/3 positive integer/},
                                                      "need 3 values rgb to convert color from rgb to hsl";

@hsl = Chart::Color::Value::hsl_from_rgb(127, 127, 127);
is( int @hsl,  3,     'converted color grey has hsl values');
is( $hsl[0],   0,     'converted color grey has computed right hue value');
is( $hsl[1],   0,     'converted color grey has computed right saturation');
is( $hsl[2],  50,     'converted color grey has computed right lightness');

@rgb = Chart::Color::Value::rgb_from_hsl(0, 0, 50);
is( int @rgb,  3,     'converted back color grey has rgb values');
is( $rgb[0], 128,     'converted back color grey has right red value');
is( $rgb[1], 128,     'converted back color grey has right green value');
is( $rgb[2], 128,     'converted back color grey has right blue value');

warning_like {$d_rgb->()}                         {carped => qr/two triplets/},"can't get distance without rgb values";
warning_like {$d_rgb->( [1,1,1],[1,1,1],[1,1,1])} {carped => qr/two triplets/},'too many array arg';
warning_like {$d_rgb->( [1,2],[1,2,3])}           {carped => qr/two triplets/},'first color is missing a value';
warning_like {$d_rgb->( [1,2,3],[2,3])}           {carped => qr/two triplets/},'second color is missing a value';
warning_like {$d_rgb->( [-1,2,3],[1,2,3])}        {carped => qr/red value/},   'first red value is too small';
warning_like {$d_rgb->( [1,2,3],[2,256,3])}       {carped => qr/green value/}, 'second green value is too large';
warning_like {$d_rgb->( [1,2,-3],[2,25,3])}       {carped => qr/blue value/},  'first blue value is too large';
warning_like {$d_hsl->( []) }                     {carped => qr/two triplets/},"can't get distance without hsl values";
warning_like {$d_hsl->( [1,1,1],[1,1,1],[1,1,1])} {carped => qr/two triplets/},'too many array arg';
warning_like {$d_hsl->( [1,2],[1,2,3])}           {carped => qr/two triplets/},'first color is missing a value';
warning_like {$d_hsl->( [1,2,3],[2,3])}           {carped => qr/two triplets/},'second color is missing a value';
warning_like {$d_hsl->( [-1,2,3],[1,2,3])}        {carped => qr/hue value/},   'first hue value is too small';
warning_like {$d_hsl->( [1,2,3],[360,2,3])}       {carped => qr/hue value/},   'second hue value is too large';
warning_like {$d_hsl->( [1,-1,3],[2,10,3])}       {carped => qr/saturation value/},'first saturation value is too small';
warning_like {$d_hsl->( [1,2,3],[2,101,3])}       {carped => qr/saturation value/},'second saturation value is too large';
warning_like {$d_hsl->( [1,1,-1],[2,10,3])}       {carped => qr/lightness value/}, 'first lightness value is too small';
warning_like {$d_hsl->( [1,2,3],[2,1,101])}       {carped => qr/lightness value/}, 'second lightness value is too large';

is( Chart::Color::Value::distance_rgb([1, 2, 3], [  2, 6, 11]), 9,     'compute rgb distance');
is( Chart::Color::Value::distance_hsl([1, 2, 3], [  2, 6, 11]), 9,     'compute hsl distance');
is( Chart::Color::Value::distance_hsl([0, 2, 3], [359, 6, 11]), 9,     'compute hsl distance (test circular property of hsl)');


is( $rgb2h->(0,0,0),          '#000000',     'converted black from rgb to hex');
is( uc $rgb2h->(255,255,255), '#FFFFFF',     'converted white from rgb to hex');
is( uc $rgb2h->( 10, 20, 30), '#0A141E',     'converted random color from rgb to hex');

@rgb = Chart::Color::Value::rgb_from_hex('#000000');
is( $rgb[0],   0,     'converted black from hex to RGB red is correct');
is( $rgb[1],   0,     'converted black from hex to RGB green is correct');
is( $rgb[2],   0,     'converted black from hex to RGB blue is correct');

@rgb = Chart::Color::Value::rgb_from_hex('#FFF');
is( $rgb[0], 255,     'converted white (short form) from hex to RGB red is correct');
is( $rgb[1], 255,     'converted white (short form) from hex to RGB green is correct');
is( $rgb[2], 255,     'converted white (short form) from hex to RGB blue is correct');

@rgb = Chart::Color::Value::rgb_from_hex('#0a141e');
is( $rgb[0],  10,     'converted random color (lower case) from hex to RGB red is correct');
is( $rgb[1],  20,     'converted random color (lower case) from hex to RGB green is correct');
is( $rgb[2],  30,     'converted random color (lower case) from hex to RGB blue is correct');



exit 0;
