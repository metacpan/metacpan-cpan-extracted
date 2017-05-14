#!/usr/bin/perl

use Test;
BEGIN { plan tests => 2 }

eval "use Class::MakeMethods 1.0;";
ok( ! $@ );

eval "use Class::MakeMethods 2000;";
ok( $@ );
