
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use Test::More;
eval "use Test::Synopsis";
plan skip_all => "Test::Synopsis required" if $@;
all_synopsis_ok();
