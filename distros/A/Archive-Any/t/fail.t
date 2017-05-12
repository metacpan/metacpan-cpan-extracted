#!/usr/bin/perl -w

use Archive::Any;
use Test::More tests => 1;

chdir 't';
ok( !Archive::Any->new( "im_not_really_a.zip" ) );
