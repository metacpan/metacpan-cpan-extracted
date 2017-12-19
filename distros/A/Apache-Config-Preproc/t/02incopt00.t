# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
plan test => 1;

use TestPreproc;
# Test IncludeOptional
my $obj = new TestPreproc '-compact';
ok($obj->dump_raw, $obj->dump_expect);
__DATA__
!>httpd.conf
ServerType standalone
ServerRoot "$server_root"
IncludeOptional conf.d/*.conf
PidFile logs/httpd.pid
!>conf.d/a.conf
Timeout 300
!>conf.d/b.conf
MaxKeepAliveRequests 100
!>conf.d/c
Other Statement
!>conf.d/z.conf
User apache
Group apache
!=
ServerType standalone
ServerRoot "$server_root"
Timeout 300
MaxKeepAliveRequests 100
User apache
Group apache
PidFile logs/httpd.pid
!$
