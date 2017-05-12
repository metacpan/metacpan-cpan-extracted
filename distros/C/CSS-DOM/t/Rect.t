#!/usr/bin/perl -T

use strict; use warnings;
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use CSS::DOM::Value::Primitive ':all';
my $prim = "CSS::DOM::Value::Primitive";


use tests 4;
{
 my $v = new $prim type => CSS_RECT, value => [
              [type=>CSS_PX,value=>1],
              [type=>CSS_EMS,value=>2],
              [type=>CSS_IDENT,value=>'auto'],
              [type=>CSS_CM,value=>4],
 ];
 is $v->top->cssText, '1px', 'top';
 is $v->right->cssText, '2em', 'right';
 is $v->bottom->cssText, 'auto', 'bottom';
 is $v->left->cssText, '4cm', 'left';
}

# ~~~ test for modifications of the cssText property