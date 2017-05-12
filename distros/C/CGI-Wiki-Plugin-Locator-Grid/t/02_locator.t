use strict;
use CGI::Wiki::Plugin::Locator::Grid;
use CGI::Wiki::TestLib;
use Test::More;

my $iterator = CGI::Wiki::TestLib->new_wiki_maker;

unless ( $iterator->number ) {
    plan skip_all => "No backends configured";
    exit 0;
}

plan tests => ( $iterator->number * 21 );

while ( my $wiki = $iterator->new_wiki ) {
      print "# Store: " . (ref $wiki->store) . "\n";
      my $locator = eval { CGI::Wiki::Plugin::Locator::Grid->new; };
      is( $@, "", "'new' doesn't croak" );
      isa_ok( $locator, "CGI::Wiki::Plugin::Locator::Grid" );
      $wiki->register_plugin( plugin => $locator );

      $wiki->write_node( "Jerusalem Tavern",
			 "Pub in Clerkenwell with St Peter's beer.",
			 undef,
			 { x => 531674,
			   y => 181950
			 }
		       ) or die "Can't write node";

      $wiki->write_node( "Calthorpe Arms",
			 "Hmmm, beeer.",
			 undef,
			 { x => 530780,
			   y => 182355
			 }
		       ) or die "Can't write node";

      $wiki->write_node( "Albion",
			 "Pub in Islington",
			 undef,
			 { x => 531206,
			   y => 183965 }
		       ) or die "Can't write node";

      $wiki->write_node( "Duke of Cambridge",
			 "Pub in Islington",
			 undef,
			 { x => 531987,
			   y => 183417 }
		       ) or die "Can't write node";

      $wiki->write_node( "Ken Livingstone",
			 "Congestion charge hero"
		       ) or die "Can't write node";

      $wiki->write_node( "22",
			 "grid point",
			 undef,
			 { x => 2000,
			   y => 2000 }
		       ) or die "Can't write node";

      $wiki->write_node( "11",
			 "grid point",
			 undef,
			 { x => 1000,
			   y => 1000 }
		       ) or die "Can't write node";

      $wiki->write_node( "21",
			 "grid point",
			 undef,
			 { x => 2000,
			   y => 1000 }
		       ) or die "Can't write node";

      $wiki->write_node( "21 clone",
			 "grid point clone",
			 undef,
			 { x => 2000,
			   y => 1000 }
		       ) or die "Can't write node";

      # Co-ordinates.
      my ( $x, $y ) = $locator->coordinates( node => "Jerusalem Tavern"   );
      is_deeply( [ $x, $y ], [ 531674, 181950 ], "->coordinates works" );

      # Distance between two places.
      my $distance = $locator->distance( from_node => "Jerusalem Tavern",
                                         to_node   => "Calthorpe Arms"    );
      my $otherway = $locator->distance( to_node   => "Jerusalem Tavern",
                                         from_node => "Calthorpe Arms"    );

      print "# Distance is $distance m\n";
      print "# Or in the other direction is $otherway m\n";
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
      $distance = $locator->distance(from_x => 531467,
                                     from_y => 183246,
                                     to_node   => "Duke of Cambridge" );
      is( $distance, 547, "->distance works with start point as co-ords" );

      $distance = $locator->distance(from_node => "Duke of Cambridge",
                                     to_x   => 531206,
                                     to_y   => 183965 );
      is( $distance, 954, "...and with end point as co-ords" );

      ##### find_within_distance with start point as co-ords
      my @things = $locator->find_within_distance( x      => 530774,
                                                   y      => 182260,
                                                   metres => 400 );
      is_deeply( \@things, [ "Calthorpe Arms" ],
                 "->find_within_distance works with start point as co-ords" );

      ##### Check that we're accessing the *latest* data.
      my %node_data = $wiki->retrieve_node( "Calthorpe Arms" );
      $wiki->write_node( "Calthorpe Arms",
                         "Let's pretend it's in Islington.",
                         $node_data{checksum},
                         { x => 531900,
                           y => 183500 }
                       ) or die "Can't write node";

      # ...co-ordinates
      ($x, $y) = $locator->coordinates( node => "Calthorpe Arms" );
      is_deeply( [ $x, $y ], [ 531900, 183500 ],
                 "->coordinates picks up latest data, not old stuff" );

      # ...distance
      $distance = $locator->distance( from_node => "Duke of Cambridge",
                                      to_node   => "Calthorpe Arms" );
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

      # Check that distinct things with identical co-ords are found.
      my @nodes = $locator->find_within_distance(
                                                  node   => "21",
                                                  metres => 5,
                                                );
      is_deeply( \@nodes, [ "21 clone" ],
                 "find_within_distance finds nodes with identical co-ords" );

}


