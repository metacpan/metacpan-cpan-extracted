#!perl -T

use Test::More tests => 1;

BEGIN {
  BAIL_OUT("can't import :schema tag")
    if not use_ok('App::Getconf', ":schema");
}

diag("Testing App::Getconf $App::Getconf::VERSION, Perl $], $^X");

# vim:ft=perl
