# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
plan test => 1;

use TestPreproc;

my $obj = new TestPreproc -expand => [qw(locus ifmodule)];
ok($obj->dump_reformat_synclines, $obj->dump_expect);

__DATA__
!>httpd.conf
LoadModule mpm_prefork_module lib/httpd/modules/mod_mpm_prefork.so
LoadModule unixd_module lib/httpd/modules/mod_unixd.so

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
!=
# {{$server_root/httpd.conf}}:1
LoadModule mpm_prefork_module lib/httpd/modules/mod_mpm_prefork.so
# {{$server_root/httpd.conf}}:2
LoadModule unixd_module lib/httpd/modules/mod_unixd.so
# {{$server_root/httpd.conf}}:3

# {{$server_root/httpd.conf}}:5
PidFile "/var/run/httpd.pid"
# {{$server_root/httpd.conf}}:8
StartServers 1
# {{$server_root/httpd.conf}}:9
MinSpareServers 1
# {{$server_root/httpd.conf}}:10
MaxSpareServers 1
# {{$server_root/httpd.conf}}:11
MaxClients 10
# {{$server_root/httpd.conf}}:12
MaxRequestsPerChild 0
# {{$server_root/httpd.conf}}:43
User apache
# {{$server_root/httpd.conf}}:44
Group apache
!$
