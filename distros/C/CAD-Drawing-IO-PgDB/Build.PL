
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
	module_name         => 'CAD::Drawing::IO::PgDB',
	license             => 'perl',
	dist_version_from   => 'lib/CAD/Drawing/IO/PgDB.pm',
	requires => {
		'Test::More'    => 0,
		'CAD::Drawing'  => '0.26',
		'DBI'           => '1.4',
		'DBD::Pg'       => '1.32',
	},
	add_to_cleanup      => [ qw(CAD-Drawing-IO-PgDB-* META.yml)],
);

$builder->create_build_script();
