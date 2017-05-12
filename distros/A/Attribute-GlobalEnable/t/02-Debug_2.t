## test ALL on to level 2 ##

use strict;
use warnings;
BEGIN {
  $ENV{ ALL_TEST_MODULE } = 2;
}

use Test::More tests => 2;
use lib qw( blib/lib t/lib);
use Attribute::GlobalEnable::TestModule;

## should have stuff loaded at this point ##

sub test_a : Test {
  my $ret1 = Test(TEST_FLAG_A, "test_a") || '';

  my $ret2 = Test("test_a") || '';

  my $all_ret = join( " ", "R: test_a", @_, $ret1, $ret2);

  return $all_ret;
}

sub test_b : Bench {
  my $ret1 = Bench("test_b") || '';

  my $all_ret = join( " ", "R: test_b", @_, $ret1);
  return $all_ret;
}


## run tests ##
ok( test_a() eq 'R: test_a Test_2 test 2: test_a test 2: test_a',
  'test all on a'
);
ok( test_b() eq 'R: test_b ',  'test all off b');


