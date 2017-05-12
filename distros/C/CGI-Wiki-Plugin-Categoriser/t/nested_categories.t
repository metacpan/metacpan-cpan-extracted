use strict;
use CGI::Wiki;
use CGI::Wiki::TestConfig::Utilities;
use CGI::Wiki::Plugin::Categoriser;
use Test::More tests =>
  (1 * $CGI::Wiki::TestConfig::Utilities::num_stores);

my %stores = CGI::Wiki::TestConfig::Utilities->stores;

my ($store_name, $store);
while ( ($store_name, $store) = each %stores ) {
    SKIP: {
      skip "$store_name storage backend not configured for testing", 1
          unless $store;

      print "#\n##### TEST CONFIG: Store: $store_name\n#\n";

      my $wiki = CGI::Wiki->new( store => $store );
      my $categoriser = CGI::Wiki::Plugin::Categoriser->new;
      $wiki->register_plugin( plugin => $categoriser );

      my @subcategories = $categoriser->subcategories( category => "Pubs" );
      is_deeply( \@subcategories, [ "Pub Food" ], "->subcategories works" );

    } # end of SKIP
}
