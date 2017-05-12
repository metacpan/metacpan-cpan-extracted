use Test::More;

BEGIN { use_ok 'Data::TestImage' };
BEGIN { use_ok 'Data::TestImage::DB::USC::SIPI' };

use lib 't/lib';
require StubTestImage;

if( grep { $_ eq 'miscellaneous' } @{ Data::TestImage::DB::USC::SIPI->installed_volumes() } ) {
	my $image_file = Data::TestImage->get_image('4.2.03');
	is( $image_file->basename, "4.2.03.tiff", 'found the mandrill image' );

	my $image01_file = Data::TestImage->get_image('mandrill');
	is( $image01_file->basename, "4.2.03.tiff", 'found the mandrill image again by metadata' );
}


my $camera_file = Data::TestImage->get_image('cameraman');
is( $camera_file->basename, "cameraman.tiff", 'found the cameraman image' );

done_testing;
