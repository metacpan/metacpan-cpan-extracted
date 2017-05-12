#!/usr/bin/env perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

 
use Test::More;
eval {require Test::EOL; };
 
if ($@) {
    plan skip_all => 'Need Test::EOL installed for line ending tests';
    exit 0;
}
Test::EOL->import;
all_perl_files_ok();