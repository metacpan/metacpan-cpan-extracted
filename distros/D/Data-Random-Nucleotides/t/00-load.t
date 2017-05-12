#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::Random::Nucleotides' ) || print "Bail out!
";
}

diag( "Testing Data::Random::Nucleotides $Data::Random::Nucleotides::VERSION, Perl $], $^X" );
