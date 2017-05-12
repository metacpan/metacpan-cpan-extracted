use warnings;
use strict;

use Module::Build;

my $build = Module::Build->new(
	module_name => 'Data::Pareto',
	license => 'artistic_2',
	dist_author => 'Przemyslaw Wesolek <jest@go.art.pl>',
	requires => {
		'Scalar::Util' => 0,
		'Carp' => 0
	},
	build_requires => {
		'Test::More' => 0,
	},
	add_to_cleanup => [ 'Data-Pareto-*' ],
);
$build->create_build_script;
