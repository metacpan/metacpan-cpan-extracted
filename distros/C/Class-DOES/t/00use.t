#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 2;

use_ok "Class::DOES"
    or BAIL_OUT "module will not load!";

ok eval { 
    package Foo::Bar;
    Class::DOES->import("Some::Role") 
}, "import accepts roles"
    or BAIL_OUT "import doesn't work right!";
