#! perl -I. -w -T
use t::Test::abeltje;


BEGIN {
    use_ok('Business::IBAN::Validator');
}

diag(
    "Testing Business::IBAN::Validator $Business::IBAN::Validator::VERSION, Perl $], $^X"
);

abeltje_done_testing(2);
