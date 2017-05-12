#!perl -T

use lib qw(lib .);
use Test::Base tests => 16;

require 't/setup.pl';

use Catalyst::Request::Upload;
use Catalyst::Plugin::Upload::Image::Magick;

ok( Catalyst::Request::Upload->can("image") );
ok( Catalyst::Request::Upload->can("is_image") );
ok( Catalyst::Request::Upload->can("width") );
ok( Catalyst::Request::Upload->can("height") );

sub test_image {
    my $filename = shift;
    my $upload   = setup($filename);
    return ref $upload->image;
}

sub test_is_image {
    my $filename = shift;
    my $upload   = setup($filename);
    $upload->is_image ? "ok" : "ng";
}

sub test_width {
    my $filename = shift;
    my $upload   = setup($filename);
    return $upload->width . "px";
}

sub test_height {
    my $filename = shift;
    my $upload   = setup($filename);
    return $upload->height . "px";
}

run_is input => 'expected';

__END__

=== test create Image::Magick instance 1
--- input chomp test_image
./t/images/cpan-10.jpg
--- expected chomp
Image::Magick

=== test create Image::Magick instance 2
--- input chomp test_image
./t/images/lcamel.gif
--- expected chomp
Image::Magick

=== test create Image::Magick instance 3
--- input chomp test_image
./t/images/script.png
--- expected chomp
Image::Magick

=== test is_image 1
--- input chomp test_is_image
./t/images/cpan-10.jpg
--- expected chomp
ok

=== test is_image 2
--- input chomp test_is_image
./t/images/lcamel.gif
--- expected chomp
ok

=== test is_image 3
--- input chomp test_is_image
./t/images/script.png
--- expected chomp
ok

=== test width 1
--- input chomp test_width
./t/images/cpan-10.jpg
--- expected chomp
250px

=== test width 2
--- input chomp test_width
./t/images/lcamel.gif
--- expected chomp
72px

=== test width 3
--- input chomp test_width
./t/images/script.png
--- expected chomp
350px

=== test height 1
--- input chomp test_height
./t/images/cpan-10.jpg
--- expected chomp
77px

=== test height 2
--- input chomp test_height
./t/images/lcamel.gif
--- expected chomp
81px

=== test height 3
--- input chomp test_height
./t/images/script.png
--- expected chomp
60px
