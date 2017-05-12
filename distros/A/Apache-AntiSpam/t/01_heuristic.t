use lib 't/lib';
use strict;
use Test;
BEGIN { plan tests => 1 }

use FilterTest;
use Apache::AntiSpam::Heuristic;

my $out = filters('t/sample.txt', 'Apache::AntiSpam::Heuristic');
ok($out, qr/user at host dot network/);
