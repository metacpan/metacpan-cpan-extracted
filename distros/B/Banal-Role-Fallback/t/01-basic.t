use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Banal::Role::Fallback;

TODO: {
  local $TODO = "Write some tests!" ;
  fail('this test is TODO!');
}
done_testing;
