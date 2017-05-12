BEGIN { unshift @INC, '/home/chris/dev/perlmods/git/kane/Acme-Comment/lib'; }

use strict;
use Test::More q[no_plan];

use Acme::Comment 1.01 type => "ALGOL", one_line => 0, own_line => 0;


SKIP:{skip(q[You cannot use 'own_line' with ALGOL],3)}