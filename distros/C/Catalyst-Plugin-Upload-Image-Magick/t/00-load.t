#!perl -T

use lib qw(inc);
use Test::More tests => 3;

use_ok('Catalyst::Plugin::Upload::Image::Magick');
use_ok('Catalyst::Plugin::Upload::Image::Magick::Thumbnail');
use_ok('Catalyst::Plugin::Upload::Image::Magick::Thumbnail::Fixed');

diag(
"Testing Catalyst::Plugin::Upload::Image::Magick $Catalyst::Plugin::Upload::Image::Magick::VERSION, Perl $], $^X"
);
