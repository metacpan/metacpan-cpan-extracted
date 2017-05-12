#!perl
use strict;
use Test::More tests => 12;
# make sure all modules can be used
BEGIN {
    use_ok( 'Data::Babel' );
    use_ok( 'Data::Babel::Base' );
    use_ok( 'Data::Babel::Config' );
    use_ok( 'Data::Babel::Filter' );
    use_ok( 'Data::Babel::IdType' );
    use_ok( 'Data::Babel::Master' );
    use_ok( 'Data::Babel::MapTable' );
    use_ok( 'Data::Babel::HAH_MultiValued' );
    use_ok( 'Data::Babel::PrefixMatcher' );
    # don't check BinarySearchList, BinarySearchTree: optional (recommended) preres
    for my $subclass (qw(Exact PrefixHash Trie)) {
      use_ok( "Data::Babel::PrefixMatcher::$subclass" );
    }
  }
done_testing();
