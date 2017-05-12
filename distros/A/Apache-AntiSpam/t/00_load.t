use strict;
use Test;
BEGIN { plan tests => 2 }

use Apache::AntiSpam;
use Apache::AntiSpam::Heuristic;
use Apache::AntiSpam::HTMLEncode;
use Apache::AntiSpam::NoSpam;

use mod_perl;
ok($mod_perl::VERSION >= 1.21);

eval { require Apache::Filter; };
ok($@ || $Apache::Filter::VERSION >= 1.013);

# keep warnings silent 
$Apache::Filter::VERSION += 0;

    
