# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
plan test => 1;

use TestPreproc;
my $obj = new TestPreproc -expand => [qw(locus)];
ok($obj->dump_reformat_synclines eq $obj->dump_expect);

__DATA__
!>httpd.conf
# Start of file
ServerName localhost

ServerAdmin foo@example.net

<VirtualHost *:80>
   ServerName foo
   DocumentRoot a
   <Directory a>
     AllowOverride none
     Require all granted
   </Directory>
</VirtualHost>

<VirtualHost *:80>
  ServerName bar
  DocumentRoot b
</VirtualHost>

# End of file
!=
# {{$server_root/httpd.conf}}:1
# Start of file
# {{$server_root/httpd.conf}}:2
ServerName localhost
# {{$server_root/httpd.conf}}:3

# {{$server_root/httpd.conf}}:4
ServerAdmin foo@example.net
# {{$server_root/httpd.conf}}:5

# {{$server_root/httpd.conf}}:6-13
<VirtualHost *:80>
# {{$server_root/httpd.conf}}:7
ServerName foo
# {{$server_root/httpd.conf}}:8
DocumentRoot a
# {{$server_root/httpd.conf}}:9-12
<Directory a>
# {{$server_root/httpd.conf}}:10
AllowOverride none
# {{$server_root/httpd.conf}}:11
Require all granted
</Directory>
</VirtualHost>
# {{$server_root/httpd.conf}}:14

# {{$server_root/httpd.conf}}:15-18
<VirtualHost *:80>
# {{$server_root/httpd.conf}}:16
ServerName bar
# {{$server_root/httpd.conf}}:17
DocumentRoot b
</VirtualHost>
# {{$server_root/httpd.conf}}:19

# {{$server_root/httpd.conf}}:20
# End of file
!$
