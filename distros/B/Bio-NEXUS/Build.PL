use strict;
use warnings;
use Module::Build;
my $builder = Module::Build->new(
	'module_name' => 'Bio::NEXUS',
	'license'     => 'perl',
	'dist_author' => 'Hladish, Liang, Qiu, Yang, Gopalan, & Stoltzfus (arlin.stoltzfus@nist.gov)',
	'dist_version_from' => 'lib/Bio/NEXUS.pm',
	'requires'          => { 'Test::More' => 0 },
	'recommends'        => {
		'Clone::PP'  => 1.02,
		'Test::Deep' => 0
	},
	'add_to_cleanup' => ['Bio-NEXUS-*'],
	'script_files' => [ 
		'exec/nexplot.pl', 
		'exec/nextool.pl', 
		'exec/nex2text_tree.pl' 
	],
	'create_makefile_pl' => 'traditional',
);
$builder->create_build_script();
