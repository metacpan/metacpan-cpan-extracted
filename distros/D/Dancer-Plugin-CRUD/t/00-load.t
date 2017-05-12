#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Dancer::Plugin::CRUD');
}

diag("Testing Dancer-Plugin-CRUD $Dancer::Plugin::CRUD::VERSION, Perl $], $^X");
