#!perl -T

use Test::More tests => 2;

use lib 't/lib';

require_ok('MyApp::Config');

eval { MyApp::Config->import(-wtf); };
like(
  $@,
  qr/unknown directive/,
  'all potential filenames beginning with - are reserved',
);

