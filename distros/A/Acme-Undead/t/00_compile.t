use strict;
use warnings;
use Test::More 0.98;

BEGIN { use_ok( 'Acme::Undead' ) || print "Bail out!\n"; }
END   { no Acme::Undead }

done_testing;
