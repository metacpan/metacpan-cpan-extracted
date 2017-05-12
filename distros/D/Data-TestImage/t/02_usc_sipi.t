use Test::More;

BEGIN { use_ok 'Data::TestImage::DB::USC::SIPI' };

use lib 't/lib';
require StubTestImage;

my @installed_contains_data = grep { "$_" =~ /data\.yml/  } @{ Data::TestImage::DB::USC::SIPI->get_installed_images() };
is( scalar @installed_contains_data, 0, 'does not contain data.yml' );

is( scalar @{ Data::TestImage::DB::USC::SIPI->get_all_images() } ,  215, 'right number of images' );


done_testing;
