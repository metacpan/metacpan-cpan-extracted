# -*- perl -*-
use lib qw(t lib);
use strict;
use warnings;
use Test;
use TestHttpd;

plan test => 3;

my $x = new TestHttpd(environ => { MOCK_HTTPD_CATCH => 22 });

ok($x->name, 'Apache');
ok($x->version, '2.4.6');
ok($x->defines('MOCK_HTTPD_CATCH'), 22);
