use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Apache::Image',
    license             => 'perl',
    dist_author         => 'Scott Penrose <scottp@dd.com.au>',
    dist_version_from   => 'lib/Apache/Image.pm',
    requires => {
        'Test::More' => 0,
	'Image::Magick' => 0,
	'Apache2::TrapSubRequest' => 0,

        # 'version'    => 0,
	# Image::Thumbnail - probably... XXX
    },
    add_to_cleanup      => [ 'Apache-Image-*' ],
);

$builder->create_build_script();
