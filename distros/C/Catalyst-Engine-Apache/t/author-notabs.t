
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

use File::Spec;
use FindBin ();
use Test::More;
use Test::NoTabs;

all_perl_files_ok(qw/lib/);
