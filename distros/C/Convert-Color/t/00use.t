#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok( 'Convert::Color::RGB' );
use_ok( 'Convert::Color::RGB8' );
use_ok( 'Convert::Color::RGB16' );
use_ok( 'Convert::Color::HSV' );
use_ok( 'Convert::Color::HSL' );
use_ok( 'Convert::Color::CMY' );
use_ok( 'Convert::Color::CMYK' );

done_testing;
