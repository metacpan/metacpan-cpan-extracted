use strict;
use warnings;
use Module::Build;

use 5.006;

my $builder = Module::Build->new(
	module_name         => 'Array::Unique',
	license             => 'perl',
	dist_author         => 'Gabor Szabo <gabor@pti.co.il>',
	#dist_abstract       => 'Tie-able array that allows only unique values',
	create_makefile_pl  => 'traditional',
	create_readme       => 1,
	requires            => {
		'perl'             => '5.006',
    },
    build_requires      => {
		'Test::More'       => 0.47,
	},
);

$builder->create_build_script();

