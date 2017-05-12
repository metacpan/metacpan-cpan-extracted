use Test::More;

use_ok( 'Bing::Search::Source::Video' );
my $obj = new_ok( 'Bing::Search::Source::Video' );

ok( $obj->Market('en-US'), '..in the US');
   is( $obj->Market(), 'en-US', 'Still in the US.');

ok( $obj->Version('2.0'), 'Version 2.0');
   is( $obj->Version(), '2.0', 'Yup, 2.0.');

ok( $obj->setOption('+DisableLocationDetection'), 'Turning on DisableLocationDetection');
   is_deeply( $obj->Options, ['DisableLocationDetection'], 'Seeing if it stuck.');

ok( $obj->setOption('-DisableLocationDetection'), 'Turning it back off.');
   is_deeply( $obj->Options, [], 'Seeing if that stuck, too.');

ok( $obj->Adult('strict'), 'Setting adult to strict' );
   is( $obj->Adult(), 'strict', 'Still strict adults' );

# filters
ok( $obj->setVideo_Filter('Duration:Long'), 'Setting video filter' );
   is_deeply( $obj->Video_Filter, ['Duration:Long'], 'Checking filter..');


# sortby
ok( $obj->Video_SortBy('Date'), 'Setting the sort');
   is( $obj->Video_SortBy(), 'Date', 'Checking the sort..');




done_testing();
