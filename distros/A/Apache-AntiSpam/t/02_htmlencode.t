use lib 't/lib';
use strict;
use Test;
BEGIN { plan tests => 1 }

use FilterTest;
use Apache::AntiSpam::HTMLEncode;
my $out = filters('t/sample.txt', 'Apache::AntiSpam::HTMLEncode');

ok($out, qr/&#117;&#115;&#101;&#114;&#64;&#104;&#111;&#115;&#116;&#46;&#110;&#101;&#116;&#119;&#111;&#114;&#107;/);
