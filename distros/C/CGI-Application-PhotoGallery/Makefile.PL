use inc::Module::Install 1.00;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/CGI/Application/PhotoGallery.pm > README' );
}

perl_version '5.006';
name 'CGI-Application-PhotoGallery';
all_from 'lib/CGI/Application/PhotoGallery.pm';

requires 'File::Basename';
requires 'CGI::Application' => '4.0';
requires 'Cache::FileCache';
requires 'MIME::Types';
requires 'File::Find::Rule';
requires 'File::ShareDir';
requires 'HTTP::Date';

test_requires 'Test::More';

feature 'GD Support',
    -default => 1,
    'GD';

feature 'Image::Magick Support',
    -default => 0,
    'Image::Magick';

feature 'Imager Support',
    -default => 0,
    'Imager';

install_share;

repository 'http://github.com/bricas/cgi-application-photogallery';

WriteAll;
