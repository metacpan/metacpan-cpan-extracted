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
Define FOO
ServerName localhost
<IfDefine FOO>
   ServerAlias remote
</IfDefine>
UnDefine FOO
DocumentRoot /var
<IfDefine FOO>
   Require all granted
</IfDefine>
!=
ServerName localhost
   ServerAlias remote
DocumentRoot /var
!$