#!perl
use strict;
use Test::More tests => 4;

use_ok( "Data::SPath" );
ok( !defined &spath, "spath isnt exported by default" );
use_ok( "Data::SPath", 'spath');
ok( defined &spath, "spath is exported when requested" );

