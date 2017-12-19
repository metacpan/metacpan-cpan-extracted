# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
plan test => 1;

use TestPreproc;

my $obj = new TestPreproc -expand => [qw(include)];
ok($obj->dump_raw, $obj->dump_expect);

__DATA__
!>httpd.conf
# Main file
ServerName localhost
ServerRoot "$server_root"
Include vhost.conf
PidFile logs/httpd.pid
!>vhost.conf
# Vhost include
<VirtualHost *:80>
  ServerName foo.bar.example.com
</VirtualHost>
!=
# Main file
ServerName localhost
ServerRoot "$server_root"
# Vhost include
<VirtualHost *:80>
  ServerName foo.bar.example.com
</VirtualHost>
PidFile logs/httpd.pid
!$

