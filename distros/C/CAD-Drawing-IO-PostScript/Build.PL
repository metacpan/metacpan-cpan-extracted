
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
	module_name         => 'CAD::Drawing::IO::PostScript',
	license             => 'perl',
	dist_version_from   => 'lib/CAD/Drawing/IO/PostScript.pm',
	requires => {
		'Test::More'         => 0,
		'CAD::Drawing'       => '0.26',
		'PostScript::Simple' => '0.06',
	},
	add_to_cleanup      => [ qw(CAD-Drawing-IO-PostScript-* META.yml)],
);

$builder->create_build_script();
