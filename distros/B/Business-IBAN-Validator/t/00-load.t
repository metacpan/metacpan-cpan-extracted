#! perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Business::IBAN::Validator');
}

diag(
    "Testing Business::IBAN::Validator $Business::IBAN::Validator::VERSION, Perl $], $^X"
);
