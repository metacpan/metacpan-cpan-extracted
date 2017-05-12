use strict;
local $^W = 1;
use CGI::Wiki::TestConfig::Utilities;
use vars qw( $num_loop_tests );
BEGIN { $num_loop_tests = 2; }
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

      foreach my $node ( $wiki->list_all_nodes ) {
          $wiki->delete_node( $node );
      }
      $wiki->write_node( "Calthorpe Arms",
			 "Hmmm, beeer.",
			 undef,
			 { os_x => 530780,
			   os_y => 182355,
			 }
		       ) or die "Couldn't write node";

      $wiki->write_node( "Blue Anchor",
			 "Hmmm, beeer.",
			 undef,
			 { os_x => 522909,
			   os_y => 178232,
			 }
		       ) or die "Couldn't write node";

      ##### find_within_distance with start point as co-ords
      my @things = $locator->find_within_distance( lat    => 51.524975,
                                                   long   => -0.116250,
                                                   metres => 400 );
      is_deeply( \@things, [ "Calthorpe Arms" ],
                 "->find_within_distance works with start point as latlong" );

      my $dist = $locator->distance( from_lat  => 51.524975,
                                     from_long => -0.116250,
                                     to_node   => "Calthorpe Arms",
                                     unit      => "metres" );
      ok( $dist < 400 && $dist > 0, "->distance works with latlong" );

    } # end of SKIP
}
