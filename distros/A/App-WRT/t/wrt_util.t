#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';

use Test::More tests => 2;

require_ok('App::WRT::Util');

like(
  App::WRT::Util::file_get_contents('example/blog/files/include_me'),
  qr'content',
  'got contents of include_me'
);

1;
