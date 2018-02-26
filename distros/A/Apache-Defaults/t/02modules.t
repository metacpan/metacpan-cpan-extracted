# -*- perl -*-
use lib qw(t lib);
use strict;
use warnings;
use Test;
use TestHttpd;

plan test => 3;

my $x = new TestHttpd;

ok(join(',', $x->preloaded), 'cgi_module,so_module');
ok($x->preloaded('cgi_module'), 'mod_cgi.c');
ok(join(',', $x->preloaded('so_module','cgi_module')), 'mod_so.c,mod_cgi.c');

