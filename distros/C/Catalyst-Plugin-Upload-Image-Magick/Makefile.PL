use inc::Module::Install;

name('Catalyst-Plugin-Upload-Image-Magick');
author('Toru Yamaguchi');
abstract('Utility using ImageMagick for Catalyst::Request::Upload');
version('0.04');
license('perl');

requires('Catalyst');
requires('Catalyst::Request::Upload');
requires('Catalyst::Utils');
requires('Catalyst::Exception');

requires('Class::Accessor::Fast');
requires('File::Temp');
requires('Image::Magick');
requires('Image::Magick::Thumbnail::Fixed');

use_test_base;

auto_include;
auto_install;

WriteAll;
