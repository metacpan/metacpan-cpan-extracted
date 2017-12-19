# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
plan test => 4;

use TestPreproc;

my $obj = new TestPreproc -expand => [qw(ifmodule)];
ok($obj->dump_raw, $obj->dump_expect);

$obj = new TestPreproc -expand => [qw(ifmodule)];
ok($obj->dump_raw, $obj->dump_expect);

$obj = new TestPreproc -expand => [qw(ifmodule)];
ok($obj->dump_raw, $obj->dump_expect);

$obj = new TestPreproc -expand => [qw(ifmodule)];
ok($obj->dump_raw, $obj->dump_expect);
__DATA__
!>httpd.conf
LoadModule mpm_prefork_module lib/httpd/modules/mod_mpm_prefork.so
<IfModule log_config_module>
LogFormat "%a" combined
<IfModule logio_module>
LogFormat "%a %I %O" combinedio
</IfModule>
</IfModule>
!=
LoadModule mpm_prefork_module lib/httpd/modules/mod_mpm_prefork.so
!$
__END__
!>httpd.conf
LoadModule log_config_module lib/httpd/modules/mod_log_config.so
<IfModule log_config_module>
LogFormat "%a" combined
<IfModule logio_module>
LogFormat "%a %I %O" combinedio
</IfModule>
</IfModule>
!=
LoadModule log_config_module lib/httpd/modules/mod_log_config.so
LogFormat "%a" combined
!$
__END__
!>httpd.conf
LoadModule log_config_module lib/httpd/modules/mod_log_config.so
LoadModule logio_module lib/httpd/modules/mod_logio.so
<IfModule log_config_module>
LogFormat "%a" combined
<IfModule logio_module>
LogFormat "%a %I %O" combinedio
</IfModule>
</IfModule>
!=
LoadModule log_config_module lib/httpd/modules/mod_log_config.so
LoadModule logio_module lib/httpd/modules/mod_logio.so
LogFormat "%a" combined
LogFormat "%a %I %O" combinedio
!$
__END__
!>httpd.conf
LoadModule logio_module lib/httpd/modules/mod_logio.so
<IfModule log_config_module>
LogFormat "%a" combined
<IfModule logio_module>
LogFormat "%a %I %O" combinedio
</IfModule>
</IfModule>
!=
LoadModule logio_module lib/httpd/modules/mod_logio.so
!$

