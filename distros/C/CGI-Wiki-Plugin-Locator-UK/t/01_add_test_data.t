use strict;

use CGI::Wiki::TestConfig::Utilities;
use CGI::Wiki;

use Test::More tests => $CGI::Wiki::TestConfig::Utilities::num_stores;

# Add test data to the stores.
my %stores = CGI::Wiki::TestConfig::Utilities->stores;

my ($store_name, $store);
while ( ($store_name, $store) = each %stores ) {
    SKIP: {
      skip "$store_name storage backend not configured for testing", 1
          unless $store;

      print "#\n##### TEST CONFIG: Store: $store_name\n#\n";

      my $wiki = CGI::Wiki->new( store => $store );

      $wiki->write_node( "Jerusalem Tavern",
			 "Pub in Clerkenwell with St Peter's beer.",
			 undef,
			 { os_x => 531674,
			   os_y => 181950
			 }
		       );

      $wiki->write_node( "Calthorpe Arms",
			 "Hmmm, beeer.",
			 undef,
			 { os_x => 530780,
			   os_y => 182355
			 }
		       );

      $wiki->write_node( "Albion",
			 "Pub in Islington",
			 undef,
			 { os_x => 531206,
			   os_y => 183965 }
			);

      $wiki->write_node( "Duke of Cambridge",
			 "Pub in Islington",
			 undef,
			 { os_x => 531987,
			   os_y => 183417 }
			);

      $wiki->write_node( "Ken Livingstone",
			 "Congestion charge hero" );

      $wiki->write_node( "22",
			 "grid point",
			 undef,
			 { os_x => 2000,
			   os_y => 2000 }
			);

      $wiki->write_node( "11",
			 "grid point",
			 undef,
			 { os_x => 1000,
			   os_y => 1000 }
			);

      $wiki->write_node( "21",
			 "grid point",
			 undef,
			 { os_x => 2000,
			   os_y => 1000 }
			);

      $wiki->write_node( "21 clone",
			 "grid point clone",
			 undef,
			 { os_x => 2000,
			   os_y => 1000 }
			);

      pass "$store_name test backend primed with test data";
    }
}
