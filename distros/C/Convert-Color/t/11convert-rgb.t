#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Convert::Color::RGB;

my $red = Convert::Color::RGB->new( 1, 0, 0 );

my $red_rgb8 = $red->convert_to("rgb8");
is( $red_rgb8->red,   255, 'red RGB8 red' );
is( $red_rgb8->green,   0, 'red RGB8 green' );
is( $red_rgb8->blue,    0, 'red RGB8 blue' );

my $red_hsv = $red->convert_to("hsv");
is( $red_hsv->hue,          0, 'red HSV hue' );
is( $red_hsv->saturation,   1, 'red HSV saturation' );
is( $red_hsv->value,        1, 'red HSV value' );

my $red_hsl = $red->convert_to("hsl");
is( $red_hsl->hue,          0, 'red HSL hue' );
is( $red_hsl->saturation,   1, 'red HSL saturation' );
is( $red_hsl->lightness,  0.5, 'red HSL lightness' );

my $red_cmy = $red->convert_to("cmy");
is( $red_cmy->cyan,    0, 'red CMY cyan' );
is( $red_cmy->magenta, 1, 'red CMY magenta' );
is( $red_cmy->yellow,  1, 'red CMY yellow' );

my $red_cmyk = $red->convert_to("cmyk");
is( $red_cmyk->cyan,    0, 'red CMYK cyan' );
is( $red_cmyk->magenta, 1, 'red CMYK magenta' );
is( $red_cmyk->yellow,  1, 'red CMYK yellow' );
is( $red_cmyk->key,     0, 'red CMYK key' );

my $green = Convert::Color::RGB->new( 0, 1, 0 );

my $green_hsv = $green->convert_to("hsv");
is( $green_hsv->hue,        120, 'green HSV hue' );
is( $green_hsv->saturation,   1, 'green HSV saturation' );
is( $green_hsv->value,        1, 'green HSV value' );

my $green_hsl = $green->convert_to("hsl");
is( $green_hsl->hue,        120, 'green HSL hue' );
is( $green_hsl->saturation,   1, 'green HSL saturation' );
is( $green_hsl->lightness,  0.5, 'green HSL lightness' );

my $green_cmy = $green->convert_to("cmy");
is( $green_cmy->cyan,    1, 'green CMY cyan' );
is( $green_cmy->magenta, 0, 'green CMY magenta' );
is( $green_cmy->yellow,  1, 'green CMY yellow' );

my $green_cmyk = $green->convert_to("cmyk");
is( $green_cmyk->cyan,    1, 'green CMYK cyan' );
is( $green_cmyk->magenta, 0, 'green CMYK magenta' );
is( $green_cmyk->yellow,  1, 'green CMYK yellow' );
is( $green_cmyk->key,     0, 'green CMYK key' );

my $blue = Convert::Color::RGB->new( 0, 0, 1 );

my $blue_hsv = $blue->convert_to("hsv");
is( $blue_hsv->hue,        240, 'blue HSV hue' );
is( $blue_hsv->saturation,   1, 'blue HSV saturation' );
is( $blue_hsv->value,        1, 'blue HSV value' );

my $blue_hsl = $blue->convert_to("hsl");
is( $blue_hsl->hue,        240, 'blue HSL hue' );
is( $blue_hsl->saturation,   1, 'blue HSL saturation' );
is( $blue_hsl->lightness,  0.5, 'blue HSL lightness' );

my $blue_cmy = $blue->convert_to("cmy");
is( $blue_cmy->cyan,    1, 'blue CMY cyan' );
is( $blue_cmy->magenta, 1, 'blue CMY magenta' );
is( $blue_cmy->yellow,  0, 'blue CMY yellow' );

my $blue_cmyk = $blue->convert_to("cmyk");
is( $blue_cmyk->cyan,    1, 'blue CMYK cyan' );
is( $blue_cmyk->magenta, 1, 'blue CMYK magenta' );
is( $blue_cmyk->yellow,  0, 'blue CMYK yellow' );
is( $blue_cmyk->key,     0, 'blue CMYK key' );

my $white = Convert::Color::RGB->new( 1, 1, 1 );

my $white_hsv = $white->as_hsv;
is( $white_hsv->hue,          0, 'white HSV hue' );
is( $white_hsv->saturation,   0, 'white HSV saturation' );
is( $white_hsv->value,        1, 'white HSV value' );

my $white_hsl = $white->as_hsl;
is( $white_hsl->hue,          0, 'white HSL hue' );
is( $white_hsl->saturation,   0, 'white HSL saturation' );
is( $white_hsl->lightness,    1, 'white HSL lightness' );

my $white_cmy = $white->as_cmy;
is( $white_cmy->cyan,    0, 'white CMY cyan' );
is( $white_cmy->magenta, 0, 'white CMY magenta' );
is( $white_cmy->yellow,  0, 'white CMY yellow' );

my $white_cmyk = $white->convert_to("cmyk");
is( $white_cmyk->cyan,    0, 'white CMYK cyan' );
is( $white_cmyk->magenta, 0, 'white CMYK magenta' );
is( $white_cmyk->yellow,  0, 'white CMYK yellow' );
is( $white_cmyk->key,     0, 'white CMYK key' );

my $black = Convert::Color::RGB->new( 0, 0, 0 );

my $black_hsv = $black->as_hsv;
is( $black_hsv->hue,          0, 'black HSV hue' );
is( $black_hsv->saturation,   0, 'black HSV saturation' );
is( $black_hsv->value,        0, 'black HSV value' );

my $black_hsl = $black->as_hsl;
is( $black_hsl->hue,          0, 'black HSL hue' );
is( $black_hsl->saturation,   0, 'black HSL saturation' );
is( $black_hsl->lightness,    0, 'black HSL lightness' );

my $black_cmy = $black->as_cmy;
is( $black_cmy->cyan,    1, 'black CMY cyan' );
is( $black_cmy->magenta, 1, 'black CMY magenta' );
is( $black_cmy->yellow,  1, 'black CMY yellow' );

my $black_cmyk = $black->convert_to("cmyk");
is( $black_cmyk->cyan,    0, 'black CMYK cyan' );
is( $black_cmyk->magenta, 0, 'black CMYK magenta' );
is( $black_cmyk->yellow,  0, 'black CMYK yellow' );
is( $black_cmyk->key,     1, 'black CMYK key' );

done_testing;
