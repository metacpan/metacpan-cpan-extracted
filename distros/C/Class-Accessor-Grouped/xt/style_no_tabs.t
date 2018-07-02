use strict;
use warnings;
use Test::More;
BEGIN {
  eval 'use Test::NoTabs 0.03; 1'
    or plan skip_all => 'Test::NoTabs 0.03 not installed';
}

all_perl_files_ok('lib');
