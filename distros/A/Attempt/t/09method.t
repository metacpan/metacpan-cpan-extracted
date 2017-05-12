#!/usr/bin/perl

use FindBin;
use File::Spec::Functions;
use lib (catdir($FindBin::Bin,"mylib"));

use Test::More tests => 1;

use My::Package;
use My::Subclass;

is(My::Subclass->foo,"bar","and it's full of stars");

