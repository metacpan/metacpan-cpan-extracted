package MockHttpd;
use strict;
use warnings;

unless (caller) {
    my $arg = shift @ARGV;
    if ($arg && !@ARGV) {
	if ($arg eq '-V') {
	    version();
	    exit(0);
	} elsif ($arg eq '-l') {
	    modules();
	    exit(0);
	}
    }
    print STDERR $0 . ' ' . __PACKAGE__ . " -l | -V\n";
    exit(1);
}    

sub version {
    print <<'EOT';
Server version: Apache/2.4.6 (Unix)
Server built:   Aug  5 2013 16:32:54
Server's Module Magic Number: 20120211:23
Server loaded:  APR 1.4.6, APR-UTIL 1.5.1
Compiled using: APR 1.4.6, APR-UTIL 1.5.1
Architecture:   64-bit
Server MPM:     event
  threaded:     yes (fixed thread count)
    forked:     yes (variable process count)
Server compiled with....
 -D APR_HAS_SENDFILE
 -D APR_HAS_MMAP
 -D APR_HAVE_IPV6 (IPv4-mapped addresses enabled)
 -D APR_USE_SYSVSEM_SERIALIZE
 -D APR_USE_PTHREAD_SERIALIZE
 -D SINGLE_LISTEN_UNSERIALIZED_ACCEPT
 -D APR_HAS_OTHER_CHILD
 -D AP_HAVE_RELIABLE_PIPED_LOGS
 -D DYNAMIC_MODULE_LIMIT=256
 -D HTTPD_ROOT="/usr"
 -D SUEXEC_BIN="/usr/bin/suexec"
 -D DEFAULT_PIDLOG="/var/run/httpd.pid"
 -D DEFAULT_SCOREBOARD="logs/apache_runtime_status"
 -D DEFAULT_ERRORLOG="logs/error_log"
 -D AP_TYPES_CONFIG_FILE="/etc/httpd/mime.types"
 -D SERVER_CONFIG_FILE="/etc/httpd/httpd.conf"
EOT
;
    if ($ENV{MOCK_HTTPD_CATCH}) {
        print " -D MOCK_HTTPD_CATCH=\"$ENV{MOCK_HTTPD_CATCH}\"\n";
    }
}

sub modules {
    print <<'EOT';
Compiled in modules:
  core.c
  mod_so.c
  http_core.c
  mod_cgi.c
EOT
;
}

1;
