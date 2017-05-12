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
			 { category => [ "Pubs" ]
			 }
		       );

      $wiki->write_node( "Calthorpe Arms",
			 "Hmmm, beeer.",
			 undef,
			 { category => [ "Pubs", "Pub Food" ]
			 }
		       );

      $wiki->write_node( "Albion",
			 "Pub in Islington",
			 undef,
			 { category => [ "Pubs", "Pub Food" ]
                         }
			);


      $wiki->write_node( "Ken Livingstone",
			 "Congestion charge hero",
                         undef,
                         { category => [ "People" ]
                         }
                        );

      $wiki->write_node( "Category Pub Food",
                         "pubs that serve food",
                         undef,
                         {
                             category => [ "Pubs", "Food", "Category" ]
                         }
                       );

      pass "$store_name test backend primed with test data";

    } # end of SKIP
}
