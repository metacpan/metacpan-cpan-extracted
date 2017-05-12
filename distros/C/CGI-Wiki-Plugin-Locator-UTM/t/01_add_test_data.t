use strict;

use CGI::Wiki::TestConfig::Utilities;
use CGI::Wiki;

use CGI::Wiki::Plugin::Locator::UTM;

use Test::More tests => $CGI::Wiki::TestConfig::Utilities::num_stores + 1;

# Add test data to the stores.
my %stores = CGI::Wiki::TestConfig::Utilities->stores;

my $locator = CGI::Wiki::Plugin::Locator::UTM->new;

isa_ok($locator, 'CGI::Wiki::Plugin::Locator::UTM', "Got plugin");

my ($store_name, $store);
while ( ($store_name, $store) = each %stores ) {
    SKIP: {
      skip "$store_name storage backend not configured for testing", 1
          unless $store;

      print "#\n##### TEST CONFIG: Store: $store_name\n#\n";

      my $wiki = CGI::Wiki->new( store => $store );
      $wiki->register_plugin(plugin => $locator);

      sub coords {
        my ($lat,$long) = @_;
        my ($zone,$east,$north) = $locator->coordinates(
      					lat => $lat,
      					long => $long);
        {
          lat => $lat,
          long => $long,
          zone => $zone,
          easting => $east,
          northing => $north
        }
      }
      
      $wiki->write_node( "Jerusalem Tavern",
			 "Pub in Clerkenwell with St Peter's beer.",
			 undef,
                         coords(51.521319, -0.102416)
		       );

      $wiki->write_node( "Calthorpe Arms",
			 "Hmmm, beeer.",
			 undef,
			 coords(51.524466, -0.114641)
		       );

      $wiki->write_node( "Albion",
			 "Pub in Islington",
			 undef,
			 coords(51.538837, -0.107903)
			);

      $wiki->write_node( "Duke of Cambridge",
			 "Pub in Islington",
			 undef,
			 coords(51.53373, -0.096853)
			);

      $wiki->write_node( "Ken Livingstone",
			 "Congestion charge hero" );

      $wiki->write_node( "22",
			 "grid point",
			 undef,
			 { zone => '10A',
			   easting => 2000,
			   northing => 2000 }
			);

      $wiki->write_node( "11",
			 "grid point",
			 undef,
			 { zone => '10A',
			   easting => 1000,
			   northing => 1000 }
			);

      $wiki->write_node( "21",
			 "grid point",
			 undef,
			 { zone => '10A',
			   easting => 2000,
			   northing => 1000 }
			);

      pass "$store_name test backend primed with test data";
    }
}
