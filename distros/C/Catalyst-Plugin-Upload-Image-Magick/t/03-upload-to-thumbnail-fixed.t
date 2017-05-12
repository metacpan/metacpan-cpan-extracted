#!perl -T

use lib qw(lib .);
use Test::Base tests => 2701;

require 't/setup.pl';

use Catalyst::Request::Upload;
use Catalyst::Plugin::Upload::Image::Magick;
use Catalyst::Plugin::Upload::Image::Magick::Thumbnail::Fixed;

ok( Catalyst::Request::Upload->can("thumbnail_fixed") );

sub test_image {
    my ( $filename, $format, $width, $height ) = @_;
    my $upload = setup($filename);

    return $upload->thumbnail_fixed(
        {
            density => $width . "x" . $height,
            quality => 100,
            format  => $format
        }
    );
}

for my $format (qw/jpg gif png/) {
    for my $filename ( glob("t/images/*") ) {
        for ( my $width = 10 ; $width <= 100 ; $width += 10 ) {
            for ( my $height = 10 ; $height <= 100 ; $height += 10 ) {

                my $image = test_image( $filename, $format, $width, $height );

                ok( $image, "Create thumbnail : ${width}x${height}" );
                is( $image->Get('width'),  $width,  'width compare' );
                is( $image->Get('height'), $height, 'height compare' );
            }
        }
    }
}

__END__
