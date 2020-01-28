# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
plan test => 1;

use TestPreproc;
my $obj = new TestPreproc -expand => [qw(locus macro)];
ok($obj->dump_reformat_synclines,$obj->dump_expect);

__DATA__
!>httpd.conf
# Start of file
ServerRoot "$server_root"
<Macro X $arg>
    Foo $arg
</Macro>
EndStatement true
Use X bar
!=
# $server_root/httpd.conf:1
# Start of file
# $server_root/httpd.conf:2
ServerRoot "$server_root"
# $server_root/httpd.conf:6
EndStatement true
# $server_root/httpd.conf:4
Foo bar
!$


