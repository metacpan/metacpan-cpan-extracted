# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
plan test => 1;

use TestPreproc;

my $obj = new TestPreproc -expand => [qw(compact include ifmodule macro ifdefine)];
ok($obj->dump_raw, $obj->dump_expect);
__DATA__
!>httpd.conf
# Main file
ServerName localhost
ServerRoot "$server_root"

Include conf.d/*.conf

Include mpm.conf
Include log.conf
Include vhost.conf
Include def.conf
<IfDefine FOO>
  Listen 8080
</IfDefine>
Timeout 300
!>conf.d/load.conf
# Load prefork mpm
LoadModule mpm_prefork_module lib/httpd/modules/mod_mpm_prefork.so
# Load logging modules
LoadModule log_config_module lib/httpd/modules/mod_log_config.so
LoadModule logio_module lib/httpd/modules/mod_logio.so
!>conf.d/vhost.conf
<Macro vhost $name $port $dir>
  <VirtualHost *:$port>
    # Comment
    ServerName $name
    DocumentRoot $dir

    <Directory $dir>
      Require all granted
    </Directory>
  </VirtualHost>

</Macro>
!>def.conf
Define FOO
!>mpm.conf
<IfModule !mpm_netware_module>
    PidFile "/var/run/httpd.pid"
</IfModule>
<IfModule mpm_prefork_module>
    StartServers          1
    MinSpareServers       1
    MaxSpareServers       1
    MaxClients           10
    MaxRequestsPerChild   0
</IfModule>
<IfModule mpm_worker_module>
    StartServers          2
    MaxClients          150
    MinSpareThreads      25
    MaxSpareThreads      75 
    ThreadsPerChild      25
    MaxRequestsPerChild   0
</IfModule>
<IfModule mpm_beos_module>
    StartThreads            10
    MaxClients              50
    MaxRequestsPerThread 10000
</IfModule>
<IfModule mpm_netware_module>
    ThreadStackSize      65536
    StartThreads           250
    MinSpareThreads         25
    MaxSpareThreads        250
    MaxThreads            1000
    MaxRequestsPerChild      0
    MaxMemFree             100
</IfModule>
<IfModule mpm_mpmt_os2_module>
    StartServers           2
    MinSpareThreads        5
    MaxSpareThreads       10
    MaxRequestsPerChild    0
</IfModule>
<IfModule unixd_module>
    User apache
    Group apache
</IfModule>
<IfModule mpm_winnt_module>
    ThreadsPerChild      150
    MaxRequestsPerChild    0
</IfModule>
!>log.conf
<IfModule log_config_module>
    LogFormat "%a" combined
    <IfModule logio_module>
        LogFormat "%a %I %O" combinedio
    </IfModule>
</IfModule>
!>vhost.conf
Use vhost foo 80 /var/www/foo
Use vhost bar 443 /var/www/bar
!=
ServerName localhost
ServerRoot "$server_root"
LoadModule mpm_prefork_module lib/httpd/modules/mod_mpm_prefork.so
LoadModule log_config_module lib/httpd/modules/mod_log_config.so
LoadModule logio_module lib/httpd/modules/mod_logio.so
    PidFile "/var/run/httpd.pid"
    StartServers          1
    MinSpareServers       1
    MaxSpareServers       1
    MaxClients           10
    MaxRequestsPerChild   0
    LogFormat "%a" combined
        LogFormat "%a %I %O" combinedio
  <VirtualHost *:80>
    ServerName foo
    DocumentRoot /var/www/foo
    <Directory /var/www/foo>
      Require all granted
    </Directory>
  </VirtualHost>
  <VirtualHost *:443>
    ServerName bar
    DocumentRoot /var/www/bar
    <Directory /var/www/bar>
      Require all granted
    </Directory>
  </VirtualHost>
  Listen 8080
Timeout 300
!$
