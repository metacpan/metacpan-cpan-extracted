#!perl

use strict;
use warnings;
use lib 'lib';
use CSS::SpriteMaker;

CSS::SpriteMaker->new->spritify('pics', 'pic1.png')->spurt('sprite.css');
