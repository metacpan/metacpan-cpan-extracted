BEGIN { unshift @INC, '/home/chris/dev/perlmods/git/kane/Acme-Comment/lib'; }

use strict;
use Test::More q[no_plan];

use Acme::Comment 1.01 type => "FOCAL", one_line => 1, own_line => 1;



my $ten = 10;
comment $ten = 11;

is($ten, 10, "FOCAL => own_line: 1, one_line: 1: Standard Single Line");

