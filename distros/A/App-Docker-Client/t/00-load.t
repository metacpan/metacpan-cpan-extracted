#!perl -T
use 5.16.0;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok('App::Docker::Client')            || print "Bail out!\n";
    use_ok('App::Docker::Client::Exception') || print "Bail out!\n";
}

diag("Testing App::Docker::Client $App::Docker::Client::VERSION, Perl $], $^X");
