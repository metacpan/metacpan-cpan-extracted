use strict;
use warnings;
BEGIN { chdir '../' if not -d '_build'; }
use Test::More tests => 1;
use lib qw[blib/lib];
use_ok('Alien::CSFML');
