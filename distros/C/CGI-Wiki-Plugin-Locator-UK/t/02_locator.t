use strict;

use CGI::Wiki::TestConfig::Utilities;
use CGI::Wiki;

use Test::More tests =>
  (1 + 20 * $CGI::Wiki::TestConfig::Utilities::num_stores);

use_ok( "CGI::Wiki::Plugin::Locator::UK" );

my %stores = CGI::Wiki::TestConfig::Utilities->stores;

my ($store_name, $store);
while ( ($store_name, $store) = each %stores ) {
    SKIP: {
      skip "$store_name storage backend not configured for testing", 20
          unless $store;

      print "#\n##### TEST CONFIG: Store: $store_name\n#\n";

      my $wiki = CGI::Wiki->new( store => $store );
      my $locator = eval { CGI::Wiki::Plugin::Locator::UK->new; };
      is( $@, "", "'new' doesn't croak" );
      isa_ok( $locator, "CGI::Wiki::Plugin::Locator::UK" );
      $wiki->register_plugin( plugin => $locator );

      # Co-ordinates.
      my ( $x, $y ) = $locator->coordinates( node => "Jerusalem Tavern"   );
      is_deeply( [ $x, $y ], [ 531674, 181950 ], "->coordinates works" );

      # Distance between two places.
      my $distance = $locator->distance( from_node => "Jerusalem Tavern",
                                         to_node   => "Calthorpe Arms"    );
      my $otherway = $locator->distance( to_node   => "Jerusalem Tavern",
                                         from_node => "Calthorpe Arms"    );

      print "# Distance is $distance km\n";
      print "# Or in the other direction is $otherway km\n";
      is( $distance, $otherway, "->distance seems consistent" );

      $distance = $locator->distance( from_node => "Calthorpe Arms",
				      to_node   => "Ken Livingstone" );
      is( $distance, undef, "...and returns undef if one node has no co-ords");

      $distance = $locator->distance( from_node => "Calthorpe Arms",
				      to_node   => "nonexistent node" );
      is( $distance, undef, "...or if one node does not exist" );

      # All things within a given distance.
      print "# " . $locator->distance( from_node => "Duke of Cambridge",
                                       to_node   => "Albion" ) . "\n";

      my @close = $locator->find_within_distance( node   => "Albion",
                                                  metres => 1000 );
      is_deeply( [ sort @close ], [ "Duke of Cambridge" ],
                 "find_within_distance works as expected on London data" );

      @close = $locator->find_within_distance( node   => "Albion",
                                               kilometres => 1 );
      is_deeply( [ sort @close ], [ "Duke of Cambridge" ],
                 "...with distances specified in km rather than metres too" );

      my @unit = $locator->find_within_distance( node    => "11",
                                                 metres  => 1000 );
      print "# Found: " . join(", ", @unit) . "\n";
      my %unit_hash = map { $_ => 1 } @unit;
      ok( defined $unit_hash{"21"}, "and on test grid finds things it should");
      ok( ! defined $unit_hash{"22"}, "...and not corner points" );

      ##### distance with start/end point as co-ords
      $distance = $locator->distance(from_os_x => 531467,
                                     from_os_y => 183246,
                                     to_node   => "Duke of Cambridge",
			             unit      => "metres" );
      is( $distance, 547, "->distance works with start point as co-ords" );

      $distance = $locator->distance(from_node => "Duke of Cambridge",
                                     to_os_x   => 531206,
                                     to_os_y   => 183965,
                                     unit      => "metres" );
      is( $distance, 954, "...and with end point as co-ords" );

      ##### find_within_distance with start point as co-ords
      my @things = $locator->find_within_distance( os_x => 530774,
                                                   os_y => 182260,
                                                   metres => 400 );
      is_deeply( \@things, [ "Calthorpe Arms" ],
                 "->find_within_distance works with start point as co-ords" );

      ##### Check that we're accessing the *latest* data.
      my %node_data = $wiki->retrieve_node( "Calthorpe Arms" );
      $wiki->write_node( "Calthorpe Arms",
                         "Let's pretend it's in Islington.",
                         $node_data{checksum},
                         { os_x => 531900,
                           os_y => 183500 }
                       );

      # ...co-ordinates
      ($x, $y) = $locator->coordinates( node => "Calthorpe Arms" );
      is_deeply( [ $x, $y ], [ 531900, 183500 ],
                 "->coordinates picks up latest data, not old stuff" );

      # ...distance
      $distance = $locator->distance( from_node => "Duke of Cambridge",
                                      to_node   => "Calthorpe Arms",
                                      unit      => "metres" );
      is( $distance, 120, "...as does ->distance" );
      print "# Distance is $distance m\n";


      print "# " . $locator->distance( from_node => "Jerusalem Tavern",
                                 to_node   => "Calthorpe Arms" ) . "\n";
      # ...within given distance
      @close = $locator->find_within_distance( node   => "Jerusalem Tavern",
					       metres => 1000 );
      print "# Found near JT: " . join(", ", @close) . "\n";
      my %close_hash = map { $_ => 1 } @close;
      ok( ! defined $close_hash{"Calthorpe Arms"},
	  "...as does ->find_within_distance, for things which used to be close enough but now aren't" );

      @close = $locator->find_within_distance( node   => "Duke of Cambridge",
					       metres => 125 );
      print "# Found near DoC: " . join(", ", @close) . "\n";
      %close_hash = map { $_ => 1 } @close;
      ok( defined $close_hash{"Calthorpe Arms"},
	  "...and for things which didn't use to be close enough but now are");

      # Check that we only get things once.
      @close = $locator->find_within_distance( node   => "Duke of Cambridge",
					       metres => 1250 );
      print "# Found: " . join(", ", @close) . "\n";
      my @dupes = grep { /Calthorpe Arms/ } @close;
      is( scalar @dupes, 1,
	  "...and only picks things up once, even if multiple versions exist");

      # Check we don't get deleted things.
      $wiki->delete_node("Calthorpe Arms");
      @close = $locator->find_within_distance( node   => "Duke of Cambridge",
					       metres => 125 );
      print "# Found near DoC: " . join(", ", @close) . "\n";
      is( scalar @close, 0, "...and doesn't pick up deleted nodes" );

      # Check things with no co-ordinates don't get treated as being at
      # the origin.
      my @stuff = $locator->find_within_distance( node => "Duke of Cambridge",
						  metres => 600000 );
      my %stuff_hash = map { $_ => 1 } @stuff;
      ok( ! defined $stuff_hash{"Ken Livingstone"},
	  "...or things with no co-ordinates" );
    }
}

