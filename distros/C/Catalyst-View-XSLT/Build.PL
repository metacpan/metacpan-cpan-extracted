use strict;
use Module::Build;

my %arguments = (
	license            => 'perl',
	module_name        => 'Catalyst::View::XSLT',
	requires           => {
		'Catalyst'			=> 5.70,
		'XML::LibXSLT'		=> 1.52, # for perl extension functions
		'File::Spec'		=> 3.10,
		'Data::Dumper'		=> 2.00,
		'Path::Class'		=> 0.12,
	},
	build_requires      => {
		'Test::More'		=> 0.60,
		'FindBin'			=> 1.40,
	},
	recommends          => {
	},
	create_makefile_pl => 'passthrough',
	create_readme      => 1,
	test_files         => [ glob('t/*.t'), glob('t/*/*.t') ]
);

Module::Build->new(%arguments)->create_build_script;
