#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Business::PayflowPro::Reporting');
}

diag(
"Testing Business::PayflowPro::Reporting $Business::PayflowPro::Reporting::VERSION, Perl $], $^X"
);
