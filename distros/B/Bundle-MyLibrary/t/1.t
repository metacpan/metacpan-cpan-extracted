#!/usr/bin/perl

use Test;

BEGIN { plan tests => 1 }

eval( "use Bundle::MyLibrary;" );
ok( !$@ );

