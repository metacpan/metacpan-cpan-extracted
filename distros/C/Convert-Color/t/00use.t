#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

require Convert::Color::RGB;
require Convert::Color::RGB8;
require Convert::Color::RGB16;
require Convert::Color::HSV;
require Convert::Color::HSL;
require Convert::Color::CMY;
require Convert::Color::CMYK;

pass "Modules loaded";
done_testing;
