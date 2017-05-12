#!perl -T

use Test::More tests => 5;

use lib 't/lib';

require_ok('MyApp::Config');

eval { MyApp::Config->import; };
is($@, '', 'we can import MyApp::Config once (with no arguments)');

ok(
  MyApp::Config->hostname,
  "then we can get data from the config",
);

eval { MyApp::Config->import; };
is($@, '', 'we can import MyApp::Config again (with no arguments)');

eval { MyApp::Config->import('filename.yaml'); };
like($@, qr/alread/, '...but we die on an attempt with a new filename');
