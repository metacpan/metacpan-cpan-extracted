#!perl -T

use lib qw(lib .);
use Test::Base tests => 1801;

require 't/setup.pl';

use Catalyst::Request::Upload;
use Catalyst::Plugin::Upload::Image::Magick;
use Catalyst::Plugin::Upload::Image::Magick::Thumbnail;

use Image::Magick;

ok( Catalyst::Request::Upload->can("thumbnail") );

sub test_image {
    my ( $filename, $format, $width, $height ) = @_;
    my $upload = setup($filename);

    return $upload->thumbnail(
        {
            density => $width . "x" . $height,
            quality => 100,
            format  => $format
        }
    );
}

for my $format (qw/jpg gif png/) {
    for my $filename ( glob("t/images/*") ) {
        my $src = Image::Magick->new;
        $src->Read($filename);

        for ( my $width = 10 ; $width <= 100 ; $width += 10 ) {
            for ( my $height = 10 ; $height <= 100 ; $height += 10 ) {

                my $image = test_image( $filename, $format, $width, $height );

                ok( $image, "Create thumbnail : ${width}x${height}" );
                ok(
                    $image->Get('width') * $image->Get('height') <=
                      $width * $height,
                    sprintf( "size limitation(%s) : src(%d : %d)\n",
                        $filename, $src->Get( 'width', 'height' ) )
                      . sprintf( "got(%d : %d)\n",
                        $image->Get('width'), $image->Get('height') )
                      . sprintf( "expected(%d : %d)", $width, $height )
                );
            }
        }
    }
}

__END__
