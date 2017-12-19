# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
plan test => 2;

use TestPreproc;
# Test recursive inclusion handling
ok(!new TestPreproc '-expect_fail', -expand => [qw(include)]);
ok($Apache::Admin::Config::ERROR, qr/level1.conf already included/);
__DATA__
!>httpd.conf
ServerType standalone
ServerRoot "$server_root"
Include level1.conf
!>level1.conf
Include level2.conf
!>level2.conf
Include level3.conf
!>level3.conf
Include level1.conf
!$
    
