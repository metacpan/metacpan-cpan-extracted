use Test::More;

use_ok('Bing::Search');
use_ok('Bing::Search::Source::MobileWeb');
my $search = new_ok('Bing::Search');

ok( $search->AppId('CHANGE THIS'), 'Setting app id' );

ok( $search->Query('yo quierro taco bell'), 'Setting query');
#   is( $search->Query(), 'rocks balls', 'Is the query still rocks?');

my $source = new_ok( 'Bing::Search::Source::MobileWeb' );

ok( $search->add_source( $source ), 'Adding Web source' );


done_testing();
