#!/usr/bin/perl

use strict;
use warnings;

use Acme::Text::Rhombus qw(rhombus);

print rhombus(
    lines   =>       31,
    letter  =>      'c',
    case    =>  'upper',
    fillup  =>      '+',
);
