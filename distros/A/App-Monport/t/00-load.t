#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('App::Monport')       || print "Bail out!\n";
}

diag("Testing App::Monport, $App::Monport::VERSION, Perl $], $^X");
