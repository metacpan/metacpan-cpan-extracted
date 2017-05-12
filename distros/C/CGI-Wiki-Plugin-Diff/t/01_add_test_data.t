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

      my %j1 = $wiki->retrieve_node( "Jerusalem Tavern");

      $wiki->write_node( "Jerusalem Tavern",
                         "Tiny pub in Clerkenwell with St Peter's beer. 
Near Farringdon station",
                         $j1{checksum},
                         { category => [ "Pubs" ]
                         }
                       );

      my %j2 = $wiki->retrieve_node( "Jerusalem Tavern");

      $wiki->write_node( "Jerusalem Tavern",
                         "Tiny pub in Clerkenwell with St Peter's beer. 
Near Farringdon station",
                         $j2{checksum},
                         { category => [ "Pubs", "Real Ale" ],
                           locale => [ "Farringdon" ]
                         }
                       );

      my %j3 = $wiki->retrieve_node( "Jerusalem Tavern");

      $wiki->write_node( "Jerusalem Tavern",
                         "Tiny pub in Clerkenwell with St Peter's beer but no food. 
Near Farringdon station",
                         $j3{checksum},
                         { category => [ "Pubs", "Real Ale" ],
                           locale => [ "Farringdon" ]
                         }
                       );
      
      $wiki->write_node( "IvorW",
      			 "
In real life:  Ivor Williams

Ideas & things to work on:

* Threaded discussion wiki
* Generify diff
* SuperSearch for CGI::Wiki
* Authentication module
* Autoindex generation
",
			 undef,
			 { username => 'Foo',
			   metatest => 'Moo' },
			);

      my %i1 = $wiki->retrieve_node( "IvorW");

      $wiki->write_node( "IvorW",
      			 $i1{content}."
[[IvorW's Test Page]]\n",
			 $i1{checksum},
			 { username => 'Bar',
			   metatest => 'Boo' },
			);
			
      my %i2 = $wiki->retrieve_node( "IvorW");

      $wiki->write_node( "IvorW",
      			 $i2{content}."
[[Another Test Page]]\n",
			 $i2{checksum},
			 { username => 'Bar',
			   metatest => 'Quack' },
			);

      my %i3 = $wiki->retrieve_node( "IvorW");
      my $newcont = $i3{content};
      $newcont =~ s/\n/ \n/s;
      $wiki->write_node( "IvorW",
      			 $newcont,
			 $i3{checksum},
			 { username => 'Bar',
			   metatest => 'Quack' },
			);

      $wiki->write_node( "Test",
      			 "a",
			 undef,
			 { },
			);

      %i3 = $wiki->retrieve_node( "Test");
      
      $wiki->write_node( "Test",
      			 "a\n",
			 $i3{checksum},
			 { },
			);

      pass "$store_name test backend primed with test data";

    } # end of SKIP
}
