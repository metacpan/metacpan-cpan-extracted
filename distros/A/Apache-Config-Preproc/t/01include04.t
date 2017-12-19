# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
plan test => 1;

use TestPreproc;
# Test whether a file can be included non-recursively multiple times
my $obj = new TestPreproc -expand => [qw(include)];
ok($obj->dump_raw, $obj->dump_expect);

__DATA__
!>httpd.conf
ServerType standalone
ServerRoot "$server_root"
<VirtualHost *:80>
  ServerName foo.bar.example.com
  Include req.conf
</VirtualHost>
<VirtualHost *:80>
  ServerName quux.example.com
  Include req.conf
</VirtualHost>
!>req.conf
Require all granted
!=    
ServerType standalone
ServerRoot "$server_root"
<VirtualHost *:80>
  ServerName foo.bar.example.com
Require all granted
</VirtualHost>
<VirtualHost *:80>
  ServerName quux.example.com
Require all granted
</VirtualHost>
!$
    
