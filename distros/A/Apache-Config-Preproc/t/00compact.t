# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
plan test => 1;

use TestPreproc;

my $obj = new TestPreproc -expand => [qw(compact)];
ok($obj->dump_raw, $obj->dump_expect);
__DATA__
!>httpd.conf
# Main file
ServerName localhost

  ServerRoot "$server_root"
# Comment 1
# Comment 2
!=
ServerName localhost
  ServerRoot "$server_root"
!$
