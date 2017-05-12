use strict;
use Test;
plan test => 14;

use Apache::Admin::Config;
ok(1);

open(HTTPD_CONF, 't/httpd.conf-dist');
ok(fileno HTTPD_CONF);

my $apache = new Apache::Admin::Config (\*HTTPD_CONF);
ok(defined $apache);

my @dirlist = $apache->directive;
ok(@dirlist, 88);

my @dirvals = $apache->directive('browsermatch');
ok(@dirvals, 5);

my $obj = $dirvals[0];
ok(defined $obj);

open(HTTPD_TMP, "+>/tmp/httpd.conf-$$-aac");
ok(fileno HTTPD_TMP);

ok($apache->save(\*HTTPD_TMP));

close(HTTPD_TMP);
open(HTTPD_TMP, "+</tmp/httpd.conf-$$-aac");

$apache = new Apache::Admin::Config \*HTTPD_TMP;
ok(defined $apache);
seek(HTTPD_TMP, 0, 0);

@dirlist = $apache->directive;
ok(@dirlist, 88);

my $rv = $apache->add_directive(test=>'bla');
ok($rv->value, 'bla');
ok($apache->save());

close(HTTPD_TMP);
open(HTTPD_TMP, "+</tmp/httpd.conf-$$-aac");

$apache = new Apache::Admin::Config \*HTTPD_TMP;
ok(defined $apache);

@dirlist = $apache->directive;
ok(@dirlist, 89);

unlink("/tmp/httpd.conf-$$-aac");
close(HTTPD_TMP);
close(HTTPD_CONF);
