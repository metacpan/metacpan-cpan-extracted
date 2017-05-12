#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Catalyst::Authentication::Store::FromSub');
}

diag(
"Testing Catalyst::Authentication::Store::FromSub $Catalyst::Authentication::Store::FromSub::VERSION, Perl $], $^X"
);
