#!/usr/bin/perl -T

use strict; use warnings;
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use CSS::DOM::Value::Primitive <CSS_RGBCOLOR CSS_NUMBER CSS_PERCENTAGE>;
my $prim = "CSS::DOM::Value::Primitive";


use tests 4; #bad
{
 my $v = new $prim type => CSS_RGBCOLOR, value => '#bad';
 is $v->red->cssText, 0xbb, 'red (#bad)';
 is $v->green->cssText, 0xaa, 'green (#bad)';
 is $v->blue->cssText, 0xdd, 'blue (#bad)';
 is $v->alpha->cssText, 1, 'alpha (#bad)';
}

use tests 4; #c0ffee
{
 my $v = new $prim type => CSS_RGBCOLOR, value => '#c0ffee';
 is $v->red->cssText, 0xc0, 'red (#c0ffee)';
 is $v->green->cssText, 255, 'green (#c0ffee)';
 is $v->blue->cssText, 0xee, 'blue (#c0ffee)';
 is $v->alpha->cssText, 1, 'alpha (#c0ffee)';
}

use tests 4; # rgb with numbers
{
 my $v = new $prim type => CSS_RGBCOLOR, value => [
              [type=>CSS_NUMBER,value=>1],
              [type=>CSS_NUMBER,value=>2],
              [type=>CSS_NUMBER,value=>27],
 ];
 is $v->red->cssText, 1, 'red (rgb with nums)';
 is $v->green->cssText, 2, 'green (rgb with nums)';
 is $v->blue->cssText, 27, 'blue (rgb with nums)';
 is $v->alpha->cssText, 1, 'alpha (rgb with nums)';
}

use tests 4; # rgb with %
{
 my $v = new $prim type => CSS_RGBCOLOR, value => [
              [type=>CSS_PERCENTAGE,value=>1],
              [type=>CSS_PERCENTAGE,value=>2],
              [type=>CSS_PERCENTAGE,value=>27],
 ];
 is $v->red->cssText, '1%', 'red (rgb with %)';
 is $v->green->cssText, '2%', 'green (rgb with %)';
 is $v->blue->cssText, '27%', 'blue (rgb with %)';
 is $v->alpha->cssText, 1, 'alpha (rgb with %)';
}

use tests 4; # rgba with numbers
{
 my $v = new $prim type => CSS_RGBCOLOR, value => [
              [type=>CSS_NUMBER,value=>1],
              [type=>CSS_NUMBER,value=>2],
              [type=>CSS_NUMBER,value=>27],
              [type=>CSS_NUMBER,value=>.7],
 ];
 is $v->red->cssText, 1, 'red (rgba with nums)';
 is $v->green->cssText, 2, 'green (rgba with nums)';
 is $v->blue->cssText, 27, 'blue (rgba with nums)';
 is $v->alpha->cssText, .7, 'alpha (rgba with nums)';
}

use tests 4; # rgba with %
{
 my $v = new $prim type => CSS_RGBCOLOR, value => [
              [type=>CSS_PERCENTAGE,value=>1],
              [type=>CSS_PERCENTAGE,value=>2],
              [type=>CSS_PERCENTAGE,value=>27],
              [type=>CSS_NUMBER,value=>.2],
 ];
 is $v->red->cssText, '1%', 'red (rgba with %)';
 is $v->green->cssText, '2%', 'green (rgba with %)';
 is $v->blue->cssText, '27%', 'blue (rgba with %)';
 is $v->alpha->cssText, 0.2, 'alpha (rgba with %)';
}

use tests 5; # named colours
{
 my $v = new $prim type => CSS_RGBCOLOR, value => 'DarkoLiveGreen';
 is $v->red->cssText, 85, 'red (named colour)';
 is $v->green->cssText, 107, 'green (named colour)';
 is $v->blue->cssText, 47, 'blue (named colour)';
 is $v->alpha->cssText, 1, 'alpha (named colour)';
 is $v->cssText, 'DarkoLiveGreen',
  'cssText still returns the same when subvalues have been accessed';
}
