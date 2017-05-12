use lib 't/lib';
use strict;
use Test;
BEGIN { plan tests => 1 }

use FilterTest;
use Apache::AntiSpam::NoSpam;

my $out = filters('t/sample.txt', 'Apache::AntiSpam::NoSpam');
ok($out, qr/user-nospam\@host\.network/);

