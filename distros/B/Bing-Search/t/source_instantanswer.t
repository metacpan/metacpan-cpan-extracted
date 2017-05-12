use Test::More;

use_ok('Bing::Search::Source::InstantAnswer');
my $obj = new_ok('Bing::Search::Source::InstantAnswer');

ok( $obj->Market('en-US'), 'Market set' );
   is( $obj->Market(), 'en-US', 'Market still in the US.' );

ok( $obj->Version('2.1'), 'Setting version' );
   is( $obj->Version, '2.1', 'Version check' );

ok( $obj->Latitude(45), 'Lattitude set' );
   is( $obj->Latitude(), '45', 'Latitude check.' );

ok( $obj->Longitude(73), 'Longitude set' );
   is( $obj->Longitude(), '73', 'Longitude check.' );


done_testing();
