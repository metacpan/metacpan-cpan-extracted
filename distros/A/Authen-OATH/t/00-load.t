#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Authen::OATH') || print "Bail out!
";
}

diag("Testing Authen::OATH $Authen::OATH::VERSION, Perl $], $^X");
