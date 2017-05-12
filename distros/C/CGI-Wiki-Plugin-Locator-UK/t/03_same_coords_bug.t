use strict;
local $^W = 1;
use CGI::Wiki::TestConfig::Utilities;
use vars qw( $num_loop_tests );
BEGIN { $num_loop_tests = 1; }
use Test::More tests =>
  (0 + $num_loop_tests * $CGI::Wiki::TestConfig::Utilities::num_stores);

use CGI::Wiki;
use CGI::Wiki::Plugin::Locator::UK;

my %stores = CGI::Wiki::TestConfig::Utilities->stores;

my ($store_name, $store);
while ( ($store_name, $store) = each %stores ) {
    SKIP: {
      skip "$store_name storage backend not configured for testing",
          $num_loop_tests
            unless $store;

      print "#\n##### TEST CONFIG: Store: $store_name\n#\n";

      my $wiki = CGI::Wiki->new( store => $store );
      my $locator = CGI::Wiki::Plugin::Locator::UK->new;
      $wiki->register_plugin( plugin => $locator );
      my @nodes = $locator->find_within_distance(
                                                  node   => "21",
                                                  metres => 5,
                                                );
      is_deeply( \@nodes, [ "21 clone" ],
                 "find_within_distance finds nodes with identical co-ords" );
    } # end of SKIP
}
