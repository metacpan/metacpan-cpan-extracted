#!perl
use strict;
use warnings;
use lib 'lib';
use blib;
use Feature::Compat::Try;

use Test::More;

plan tests => 1;

try {

  require Archive::SCS::CityHash;
  require Archive::SCS::DirIndex;
  require Archive::SCS::GameDir;
  require Archive::SCS::Mountable;
  require Archive::SCS::TObj;

  require Archive::SCS::HashFS;
  require Archive::SCS::HashFS2;
  require Archive::SCS::InMemory;

  require Archive::SCS;

  pass;

}
catch ($e) {

  fail;
  BAIL_OUT($e);

}
