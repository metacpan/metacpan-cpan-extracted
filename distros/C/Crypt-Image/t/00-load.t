#!/usr/bin/env perl

use 5.006;
use strict; use warnings;
use Test::More tests => 4;

BEGIN {
    use_ok('Crypt::Image')         || print "Bail out!";
    use_ok('Crypt::Image::Axis')   || print "Bail out!";
    use_ok('Crypt::Image::Util')   || print "Bail out!";
    use_ok('Crypt::Image::Params') || print "Bail out!";
}

diag("Testing Crypt::Image $Crypt::Image::VERSION, Perl $], $^X");
