## no critic (RCS,VERSION,encapsulation,Module)

use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    use_ok( 'Bytes::Random::Secure::Tiny' ) || print "Bail out!\n";
}

diag('Testing Bytes::Random::Secure::Tiny ' 
  . "$Bytes::Random::Secure::Tiny::VERSION, Perl $], $^X");

can_ok 'Bytes::Random::Secure::Tiny', qw( new irand string_from bytes bytes_hex );
can_ok 'Math::Random::ISAAC::Embedded', qw( new irand );
can_ok 'Math::Random::ISAAC::PP::Embedded', qw( new irand );

