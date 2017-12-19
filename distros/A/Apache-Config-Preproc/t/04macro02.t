# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
plan test => 1;

use TestPreproc;

my $obj = new TestPreproc -expand => [ { macro => [ keep => 'SSL' ] } ];
ok($obj->dump_raw, $obj->dump_expect);
__DATA__
!>httpd.conf
ServerName localhost
<Macro SSL $domain>
SSLEngine on
SSLCertificateFile /etc/ssl/acme/$domain.pem
</Macro>
<Macro vhost $name $port $dir>
<VirtualHost *:$port>
ServerName $name
DocumentRoot $dir
Use SSL $name
</VirtualHost>
</Macro>

Use vhost foo 80 /var/www/foo
!=
ServerName localhost
<Macro SSL $domain>
SSLEngine on
SSLCertificateFile /etc/ssl/acme/$domain.pem
</Macro>

<VirtualHost *:80>
ServerName foo
DocumentRoot /var/www/foo
Use SSL foo
</VirtualHost>
!$

