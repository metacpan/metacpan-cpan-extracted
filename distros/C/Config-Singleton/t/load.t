#!perl -T

use Test::More tests => 6;

use lib 't/lib';

require_ok('MyApp::Config');

eval { MyApp::Config->import; };
is($@, '', 'we can import MyApp::Config once (with a filename)');

eval { MyApp::Config->import(-load); };
is($@, '', 'we can import MyApp::Config again (with -load)');

eval { MyApp::Config->import; };
is($@, '', 'then an attempt with no filename is fine');

eval { MyApp::Config->import('etc/obj-1.yaml'); };
like($@, qr/already/, '...but we die on an attempt with a new filename');

is(MyApp::Config->username, 'faceman', "and we have loaded the default data");
