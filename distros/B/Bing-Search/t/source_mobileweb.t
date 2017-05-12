use Test::More;

use_ok('Bing::Search::Source::MobileWeb');

my $obj = new_ok('Bing::Search::Source::MobileWeb');

ok( $obj->Market('en-US'), 'Setitng the market');
   is( $obj->Market(), 'en-US', 'Market is still set');

ok( $obj->Version('2.0'), 'Setting version');
   is( $obj->Version(), '2.0', 'Version still set');

ok( $obj->setOption('+DisableLocationDetection'), 'Turning on DisableLocationDetection');
   is_deeply( $obj->Options, ['DisableLocationDetection'], 'Seeing if it stuck.');

ok( $obj->setOption('-DisableLocationDetection'), 'Turning it back off.');
   is_deeply( $obj->Options, [], 'Seeing if that stuck, too.');

ok( $obj->Latitude(45), 'Setting the latitude');
   is( $obj->Latitude(), '45', 'Still at 45?');

ok( $obj->Longitude(73), 'Setting the longitude');
   is( $obj->Longitude(), '73', 'Still at 73?');

ok( $obj->MobileWeb_Count('7'), 'Setting Count');
   is( $obj->MobileWeb_Count(),'7', 'Count still set.');

ok( $obj->MobileWeb_Offset(200), 'Setting offset');
   is( $obj->MobileWeb_Offset(), 200, 'Offset still set.');

ok( $obj->setMobileWeb_Option('DisableHostCollapsing'), 'Setting DisableHostCollapsing');
   is_deeply( $obj->MobileWeb_Options, ['DisableHostCollapsing'], 'Still set?');

ok( $obj->setMobileWeb_Option('-DisableHostCollapsing'), 'Removing the option..');
   is_deeply( $obj->MobileWeb_Options, [], 'Should be empty now.');

done_testing();
