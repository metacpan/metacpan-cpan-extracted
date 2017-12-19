# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
plan test => 1;

use TestPreproc;

my $obj = new TestPreproc '-compact';
ok($obj->dump_raw, $obj->dump_expect);
__DATA__
!>httpd.conf
ServerType standalone
ServerRoot "$server_root"
IncludeOptional conf.d/*.conf
PidFile logs/httpd.pid
!+conf.d
!=
ServerType standalone
ServerRoot "$server_root"
PidFile logs/httpd.pid
!$
