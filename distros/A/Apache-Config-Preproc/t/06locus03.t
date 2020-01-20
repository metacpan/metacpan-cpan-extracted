# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
plan test => 1;

use TestPreproc;
my $obj = new TestPreproc -expand => [qw(locus include)];
ok($obj->dump_reformat_synclines,$obj->dump_expect);

__DATA__
!>httpd.conf
# Start of file
ServerRoot "$server_root"
ServerAdmin foo@example.net
Include vhost1.conf
Include vhost2.conf
PidFile logs/httpd.pid
!>vhost1.conf
<VirtualHost *:80>
   ServerName foo
   DocumentRoot a
</VirtualHost>
!>vhost2.conf
<VirtualHost *:80>
   ServerName bar
   DocumentRoot b
</VirtualHost>
!=
# $server_root/httpd.conf:1
# Start of file
# $server_root/httpd.conf:2
ServerRoot "$server_root"
# $server_root/httpd.conf:3
ServerAdmin foo@example.net
# $server_root/vhost1.conf:1-4
<VirtualHost *:80>
# $server_root/vhost1.conf:2
ServerName foo
# $server_root/vhost1.conf:3
DocumentRoot a
</VirtualHost>
# $server_root/vhost2.conf:1-4
<VirtualHost *:80>
# $server_root/vhost2.conf:2
ServerName bar
# $server_root/vhost2.conf:3
DocumentRoot b
</VirtualHost>
# $server_root/httpd.conf:6
PidFile logs/httpd.pid
!$    
