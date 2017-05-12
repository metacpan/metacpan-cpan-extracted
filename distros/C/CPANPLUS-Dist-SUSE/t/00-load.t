#!perl

use Test::More tests => 2;

BEGIN {
    use_ok('CPANPLUS::Dist::SUSE')     || print "Bail out!";
    require_ok('CPANPLUS::Dist::SUSE') || print "Bail out!";
}

diag(
    "Testing CPANPLUS::Dist::SUSE $CPANPLUS::Dist::SUSE::VERSION, Perl $], $^X"
);
