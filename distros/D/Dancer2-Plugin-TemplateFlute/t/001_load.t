# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 1;

BEGIN {
    use_ok('Dancer2::Plugin::TemplateFlute')
      || print "Bail out!\n";
}

diag(   "Testing"
      . " Dancer2::Plugin::TemplateFlute "
      . "$Dancer2::Plugin::TemplateFlute::VERSION, "
      . "Perl $], $^X" );

