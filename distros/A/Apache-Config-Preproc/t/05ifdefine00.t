# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
plan test => 3;

use TestPreproc;

my $obj = new TestPreproc -expand => ['ifdefine'];
ok($obj->dump_raw, $obj->dump_expect);

my $obj = new TestPreproc -expand => [ { ifdefine => [qw(VAR)] } ];
ok($obj->dump_raw, $obj->dump_expect);

my $obj = new TestPreproc -expand => ['ifdefine'];
ok($obj->dump_raw, $obj->dump_expect);

__DATA__
!>httpd.conf
ServerAdmin foo
<IfDefine VAR>
  ServerName localhost
</IfDefine>
!=
ServerAdmin foo
!$
__END__
!>httpd.conf
ServerAdmin foo
<IfDefine VAR>
  ServerName localhost
</IfDefine>
!=
ServerAdmin foo
  ServerName localhost
!$
__END__
!>httpd.conf
ServerAdmin foo
<IfDefine !VAR>
  ServerName localhost
</IfDefine>
!=
ServerAdmin foo
  ServerName localhost
!$
