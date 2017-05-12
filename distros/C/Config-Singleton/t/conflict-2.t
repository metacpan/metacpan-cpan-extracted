#!perl -T

use Test::More tests => 5;

use lib 't/lib';

require_ok('MyApp::Config');

eval { MyApp::Config->import('etc/custom.yaml'); };
is($@, '', 'we can import MyApp::Config once (with a filename)');

eval { MyApp::Config->import('etc/custom.yaml'); };
is($@, '', 'we can import MyApp::Config again (with the same filename)');

eval { MyApp::Config->import; };
is($@, '', 'then an attempt with no filename is fine');

eval { MyApp::Config->import('etc/obj-1.yaml'); };
like($@, qr/already/, '...but we die on an attempt with a new filename');
