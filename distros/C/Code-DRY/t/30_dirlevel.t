use strict;
use warnings;

use Test::More tests => 1;
use Code::DRY;
#########################
can_ok('Code::DRY', 'scan_directories');

Code::DRY::scan_directories(2,undef,undef,qr{~$|\.swp$|\.bak}xms,'t');
#TODO
