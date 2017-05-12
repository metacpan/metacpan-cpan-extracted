use strict;
use CGI::Wiki;
use CGI::Wiki::TestConfig::Utilities;
use Test::More tests =>
  (1 + 6 * $CGI::Wiki::TestConfig::Utilities::num_stores);

use_ok( "CGI::Wiki::Plugin::Categoriser" );

my %stores = CGI::Wiki::TestConfig::Utilities->stores;

my ($store_name, $store);
while ( ($store_name, $store) = each %stores ) {
    SKIP: {
      skip "$store_name storage backend not configured for testing", 6
          unless $store;

      print "#\n##### TEST CONFIG: Store: $store_name\n#\n";

      my $wiki = CGI::Wiki->new( store => $store );
      my $categoriser = eval { CGI::Wiki::Plugin::Categoriser->new; };
      is( $@, "", "'new' doesn't croak" );
      isa_ok( $categoriser, "CGI::Wiki::Plugin::Categoriser" );
      $wiki->register_plugin( plugin => $categoriser );

      # Test ->in_category
      my $isa_pub = $categoriser->in_category( category => "Pubs",
                                               node     => "Albion" );
      ok( $isa_pub, "in_category returns true for things in the category" );
      $isa_pub = $categoriser->in_category( category => "Pubs",
                                            node     => "Ken Livingstone" );
      ok( !$isa_pub, "...and false for things not in the category" );

      $isa_pub = $categoriser->in_category( category => "pubs",
                                            node     => "Albion" );
      ok( $isa_pub, "...and is case-insensitive" );

      # Test ->categories
      my @categories = $categoriser->categories( node => "Calthorpe Arms" );
      is_deeply( [ sort @categories ], [ "Pub Food", "Pubs" ],
                 "...->categories returns all categories" );

    } # end of SKIP
}
