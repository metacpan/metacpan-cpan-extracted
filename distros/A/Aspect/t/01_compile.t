#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 7;
use Test::NoWarnings;

use_ok( 'Aspect'                      );
use_ok( 'Aspect::Library::Breakpoint' );
use_ok( 'Aspect::Library::Listenable' );
use_ok( 'Aspect::Library::Singleton'  );
use_ok( 'Aspect::Library::Wormhole'   );
require_ok( 'Aspect::Point::Functions' );
