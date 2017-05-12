use Test::More;

use_ok( 'Bing::Search::Source::Phonebook' );
my $obj = new_ok( 'Bing::Search::Source::Phonebook' );


ok( $obj->Market('en-US'), '..in the US');
   is( $obj->Market(), 'en-US', 'Still in the US.');

ok( $obj->Version('2.0'), 'Version 2.0');
   is( $obj->Version(), '2.0', 'Yup, 2.0.');

ok( $obj->Adult('strict'), 'Strict adults!');
   is( $obj->Adult(), 'strict', 'Draconian measures!');

ok( $obj->setOption('+DisableLocationDetection'), 'Turning on DisableLocationDetection');
   is_deeply( $obj->Options, ['DisableLocationDetection'], 'Seeing if it stuck.');

ok( $obj->setOption('-DisableLocationDetection'), 'Turning it back off.');
   is_deeply( $obj->Options, [], 'Seeing if that stuck, too.');

ok( $obj->Latitude(45), 'Setting the latitude');
   is( $obj->Latitude(), '45', 'Still at 45?');

ok( $obj->Longitude(73), 'Setting the longitude');
   is( $obj->Longitude(), '73', 'Still at 73?');

ok( $obj->Phonebook_Count(4), 'Setting the count');
   is( $obj->Phonebook_Count(), '4', 'Still set');

ok( $obj->Phonebook_Offset(20), 'Setting the offset' );
   is( $obj->Phonebook_Offset(), '20', 'Still set.');
 


done_testing();
