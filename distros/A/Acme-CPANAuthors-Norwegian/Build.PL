use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Acme::CPANAuthors::Norwegian',
	license             => 'perl',
	dist_author         => 'Anatoly Sharifulin <sharifulin@gmail.com>',
	dist_version_from   => 'lib/Acme/CPANAuthors/Norwegian.pm',
	build_requires => {
		'Test::More' => 0,
	},
	requires => {
		'Acme::CPANAuthors::Register' => 0,
		'Acme::CPANAuthors'           => 0,
		'perl'                        => 5.006, # for META.yml
	},
	meta_merge => {
		resources => {
			repository => 'http://github.com/sharifulin/acme-cpanauthors-norwegian/tree',
		},
		keywords => [
			'CPAN',
			'CPAN authors',
			'Norwegian'
		],
	},
	add_to_cleanup     => [],
	create_makefile_pl => 'traditional',
);

$builder->create_build_script();
