#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

use Test::More tests => 2;

require_ok('App::WRT::Util');

ok(
  App::WRT::Util::file_get_contents('example/files/include_me') =~ 'content',
  'got contents of include_me'
);

1;
