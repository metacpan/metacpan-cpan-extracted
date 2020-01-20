# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
plan test => 3;

use TestPreproc;

my $obj = new TestPreproc -expand => ['locus', 'ifdefine'];
ok($obj->dump_reformat_synclines, $obj->dump_expect);

$obj = new TestPreproc -expand => [ 'locus', { ifdefine => [qw(VAR)] } ];
ok($obj->dump_reformat_synclines, $obj->dump_expect);

$obj = new TestPreproc -expand => ['locus', 'ifdefine'];
ok($obj->dump_reformat_synclines, $obj->dump_expect);

__DATA__
!>httpd.conf
ServerAdmin foo
<IfDefine VAR>
  ServerName localhost
</IfDefine>
!=
# $server_root/httpd.conf:1
ServerAdmin foo
!$
__END__
!>httpd.conf
ServerAdmin foo
<IfDefine VAR>
  ServerName localhost
</IfDefine>
!=
# $server_root/httpd.conf:1
ServerAdmin foo
# $server_root/httpd.conf:3
ServerName localhost
!$
__END__
!>httpd.conf
ServerAdmin foo
<IfDefine !VAR>
  ServerName localhost
</IfDefine>
!=
# $server_root/httpd.conf:1
ServerAdmin foo
# $server_root/httpd.conf:3
ServerName localhost
!$
