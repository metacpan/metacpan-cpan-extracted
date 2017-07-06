use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    use_ok('Acme::OCEORA::Utils') || print "Bail out!\n";
}

diag("Testing Acme::OCEORA::Utils::VERSION, Perl $], $^X");

{
    my @a = (1, 2, 3);

    is(Acme::OCEORA::Utils::sum(@a),
       6,
       'Acme::OCEORA::Utils::sum((1, 2, 3)) does the right thing');
}
