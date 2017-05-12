#make sample read test
use strict;
use Test;

use lib '../lib';

BEGIN { plan tests => 1 }

use Asterisk::config;

my $sip_conf = new Asterisk::config(file=>'t/test.conf');
ok($sip_conf);
