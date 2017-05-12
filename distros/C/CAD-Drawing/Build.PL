
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';
my $custom_build = 'Module::Build::Live';
eval("require $custom_build;");
unless($@) {
	warn "using custom build class:  '$custom_build'\n";
	$build_class = $custom_build;
}

my $builder = $build_class->new(
	module_name         => 'CAD::Drawing',
	license             => 'perl',
	dist_version_from   => 'lib/CAD/Drawing.pm',
	requires => {
		'Test::More'             => 0,
		'Compress::Zlib'         => 1.41,
		'Stream::FileInputStream' => 0, # XXX kill that
		# XXX only needed for CAD::Drawing::Manipulate::Graphics
		'Image::Magick'          => 6,
		'Math::Geometry::Planar' => 1.14,
		'Math::MatrixReal'       => 1.9,
		# Eric wrote these
		'CAD::Calc'              => 0.25,
		'Math::Vec'              => '0.03',
	},
	add_to_cleanup      => [ qw(CAD-Drawing-* META.yml)],
);

$builder->create_build_script();
