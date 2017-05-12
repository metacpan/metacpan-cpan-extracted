#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 1;

use_ok( 'Audio::Play::MPlayer' )
  or BAIL_OUT( "Can't compile" );
