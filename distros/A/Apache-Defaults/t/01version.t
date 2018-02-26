# -*- perl -*-
use lib qw(t lib);
use strict;
use warnings;
use Test;
use TestHttpd;

plan test => 10;

my $x = new TestHttpd;

ok($x->name, 'Apache');
ok($x->version, '2.4.6');
ok($x->built, '2013-08-05T16:03:02');
ok($x->architecture, '64-bit');
ok($x->MPM, 'event');
ok(join("\n", $x->defines)."\n",<<EOT);
APR_HAS_MMAP
APR_HAS_OTHER_CHILD
APR_HAS_SENDFILE
APR_HAVE_IPV6
APR_USE_PTHREAD_SERIALIZE
APR_USE_SYSVSEM_SERIALIZE
AP_HAVE_RELIABLE_PIPED_LOGS
AP_TYPES_CONFIG_FILE
DEFAULT_ERRORLOG
DEFAULT_PIDLOG
DEFAULT_SCOREBOARD
DYNAMIC_MODULE_LIMIT
HTTPD_ROOT
SERVER_CONFIG_FILE
SINGLE_LISTEN_UNSERIALIZED_ACCEPT
SUEXEC_BIN
EOT
;   
ok($x->defines('APR_HAS_SENDFILE'), 1);
ok($x->defines('APR_HAVE_IPV6'), 1);
ok($x->defines('DYNAMIC_MODULE_LIMIT'), 256);
ok($x->server_root, "/usr");

