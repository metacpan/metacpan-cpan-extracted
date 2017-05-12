use Test::More skip_all => 'Author tests, need network & appid';
#use Test::More;
use strict;
use warnings;
use Data::Dumper;
$Data::Dumper::Indent = 1; # compact! 
use_ok('Bing::Search');

# check to see if we can make a new object, and then issue a request, 
# and get a response without things exploding.

for my $source (qw(Image InstantAnswer MobileWeb News Phonebook RelatedSearch Spell Translation Video Web) ) { 
   
   my $sourcename = 'Bing::Search::Source::' . $source;
   
   my $search = new_ok( 'Bing::Search' );
   ok( $search->Query('Rocks'), 'Setting query for ' . $sourcename );

   ok( $search->AppId('GET YOUR OWN'), 'Setting AppId for ' . $sourcename );
   use_ok( $sourcename );
   my $obj = new_ok( $sourcename );
   ok( $search->add_source( $obj ), 'Adding source for ' . $sourcename );
   my $result;
   ok( $result = $search->search, 'Performing search for ' . $sourcename );
   note "========================= RESULTS FOR $sourcename\n";
   note Dumper( $result );   
   note "========================= END RESULTS FOR $sourcename\n";

}

done_testing();
