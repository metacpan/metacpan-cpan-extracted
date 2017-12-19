# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
plan test => 1;

use TestPreproc;

my $obj = new TestPreproc -expand => ['ifdefine'];
ok($obj->dump_raw, $obj->dump_expect);

__DATA__
!>httpd.conf
<VirtualHost bar>
   ServerName localhost
   ServerAdmin root
   Define FOO
</VirtualHost>  
<IfDefine FOO>
   Alias /foo /bar
</IfDefine>
!=
<VirtualHost bar>
   ServerName localhost
   ServerAdmin root
</VirtualHost>  
   Alias /foo /bar
!$
