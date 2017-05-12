#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Dancer::Plugin::Transformator');
}

diag(
"Testing Dancer-Plugin-Transformator $Dancer::Plugin::Transformator::VERSION, Perl $], $^X"
);
