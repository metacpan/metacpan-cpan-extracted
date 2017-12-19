# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
plan test => 1;

use TestPreproc;

my $obj = new TestPreproc -expand => ['macro'];
ok($obj->dump_raw, $obj->dump_expect);

__DATA__
!>httpd.conf
ServerName localhost
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
Use vhost foo 80 /var/www/foo
Use vhost bar 443 /var/www/bar
Use vhost baz 80 /var/baz
!=
ServerName localhost
  <VirtualHost *:80>
    # Comment
    ServerName foo
    DocumentRoot /var/www/foo

    <Directory /var/www/foo>
      Require all granted
    </Directory>
  </VirtualHost>

  <VirtualHost *:443>
    # Comment
    ServerName bar
    DocumentRoot /var/www/bar

    <Directory /var/www/bar>
      Require all granted
    </Directory>
  </VirtualHost>

  <VirtualHost *:80>
    # Comment
    ServerName baz
    DocumentRoot /var/baz

    <Directory /var/baz>
      Require all granted
    </Directory>
  </VirtualHost>

!$
