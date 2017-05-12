BEGIN { unshift @INC, '/home/chris/dev/perlmods/git/kane/Acme-Comment/lib'; }

use strict;
use Test::More q[no_plan];

use Acme::Comment 1.01 type => "ORTHOGONAL", one_line => 1, own_line => 0;



my $ten = 10;
; $ten = 11;

is($ten, 10, "ORTHOGONAL => own_line: 0, one_line: 1: Standard Single Line");

