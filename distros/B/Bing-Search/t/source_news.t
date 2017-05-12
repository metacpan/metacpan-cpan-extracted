use Test::More;

use_ok( 'Bing::Search::Source::News' );
my $obj = new_ok( 'Bing::Search::Source::News' );

ok( $obj->Market('en-US'), '..in the US');
   is( $obj->Market(), 'en-US', 'Still in the US.');

ok( $obj->Version('2.0'), 'Version 2.0');
   is( $obj->Version(), '2.0', 'Yup, 2.0.');

ok( $obj->setOption('+DisableLocationDetection'), 'Turning on DisableLocationDetection');
   is_deeply( $obj->Options, ['DisableLocationDetection'], 'Seeing if it stuck.');

ok( $obj->setOption('-DisableLocationDetection'), 'Turning it back off.');
   is_deeply( $obj->Options, [], 'Seeing if that stuck, too.');

ok( $obj->News_Count( 3 ), 'Start at the 3rd item..');
   is( $obj->News_Count(), '3', 'Still at #3 baby.');

ok( $obj->News_Offset( 2 ), 'Offset is 2..');
   is( $obj->News_Offset(), '2', 'Still 2..');

ok( $obj->News_LocationOverride('en-GB'), 'Setting location override');
   is( $obj->News_LocationOverride(), 'en-GB', 'We in England, yo!' );

ok( $obj->News_Category('Technology'), 'Category set');
   is( $obj->News_Category(), 'Technology', 'Category check' );

ok( $obj->News_SortBy('Relevance'), 'Setting sort' );
   is( $obj->News_SortBy(), 'Relevance', 'Still sorting..');

 

done_testing();
