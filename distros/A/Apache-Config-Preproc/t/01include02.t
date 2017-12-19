# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
plan test => 1;

use TestPreproc;
# Test nested includes
my $obj = new TestPreproc -expand => [qw(include)];
ok($obj->dump_raw, $obj->dump_expect);

__DATA__
!>httpd.conf
# Main configuration
ServerType standalone
ServerRoot "$server_root"
Include "level1.conf"
PidFile logs/httpd.pid
!>level1.conf
# First-level include file
Timeout 300
Include level2.conf
KeepAlive On
!>level2.conf
# Second-level include file
MaxKeepAliveRequests 100
KeepAliveTimeout 15
!=
# Main configuration
ServerType standalone
ServerRoot "$server_root"
# First-level include file
Timeout 300
# Second-level include file
MaxKeepAliveRequests 100
KeepAliveTimeout 15
KeepAlive On
PidFile logs/httpd.pid
!$
