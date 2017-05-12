
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use Test::More;
 
eval { require Test::NoTabs; };
if ($@) { plan skip_all => 'Test::NoTabs not installed'; exit 0; }
 
Test::NoTabs::all_perl_files_ok();