package SplitSerializerTest;

use Data::SplitSerializer;
use Test::Most;
use base 'Exporter';

our @EXPORT = qw(test_both_ways);

sub test_both_ways {
   my ($dsso, $hash_start, $expect_tree, $expect_hash, $test_name) = @_;
   my ($tree, $hash);

   SKIP: {
      # deserialize/expand
      lives_ok {
         $tree = $dsso->deserialize($hash_start);
      } "$test_name deserialize didn't die" or skip "$test_name died", 5;
      is_deeply($tree, $expect_tree, "$test_name deserialized correctly") || diag explain $tree;

      # serialize/flatten
      lives_ok {
         $hash = $dsso->serialize($tree);
      } "$test_name serialize didn't die" or skip "$test_name died", 3;
      is_deeply($hash, $expect_hash, "$test_name serialized correctly") || diag explain $hash;

      # deserialize/expand
      lives_ok {
         $tree = $dsso->deserialize($hash);
      } "$test_name serialize didn't die" or skip "$test_name died", 1;
      is_deeply($tree, $expect_tree, "$test_name re-deserialized correctly") || diag explain $tree;
   };
}

42;