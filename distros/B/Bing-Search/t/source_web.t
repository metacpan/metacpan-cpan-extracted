use Test::More;

use_ok( 'Bing::Search::Source::Web' );
my $obj = new_ok( 'Bing::Search::Source::Web' );

ok( $obj->Market('en-US'), '..in the US');
   is( $obj->Market(), 'en-US', 'Still in the US.');

ok( $obj->Version('2.0'), 'Version 2.0');
   is( $obj->Version(), '2.0', 'Yup, 2.0.');

ok( $obj->setOption('+DisableLocationDetection'), 'Turning on DisableLocationDetection');
   is_deeply( $obj->Options, ['DisableLocationDetection'], 'Seeing if it stuck.');

ok( $obj->setOption('-DisableLocationDetection'), 'Turning it back off.');
   is_deeply( $obj->Options, [], 'Seeing if that stuck, too.');

ok( $obj->Latitude(45), 'Setting the latitude');
   is( $obj->Latitude(), '45', 'Still at 45?');

ok( $obj->Longitude(73), 'Setting the longitude');
   is( $obj->Longitude(), '73', 'Still at 73?');

ok( $obj->Web_Count(20), 'Setting the count' );
   is( $obj->Web_Count(), '20', 'Checking the count' );

ok( $obj->Web_Offset(10), 'Setting the offset' );
   is( $obj->Web_Offset(), '10', 'Checking the offset' );

ok( $obj->Web_FileType('PDF'), 'Setting the filetype' );
   is( $obj->Web_FileType(), 'PDF', 'Checking the filetype' );


done_testing();
