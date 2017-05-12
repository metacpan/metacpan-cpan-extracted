use strict;
use warnings;

use Alien::Base::ModuleBuild;

my $builder = Alien::Base::ModuleBuild->new(
	module_name => 'Alien::LibXML',
	license => 'mit',
	configure_requires => {
		'Alien::Base'   => '0.001',
		'Module::Build' => '0.38',
	},
	test_requires => {
		'File::Which'   => 0,
	},
	requires => {
		'perl'        => '5.8.9',
		'Alien::Base' => '0.005',
	},
	dist_author => 'Toby Inkster <tobyink@cpan.org>',
	alien_name => 'libxml-2.0',
	alien_repository => {
		protocol => 'ftp',
		host     => 'xmlsoft.org',
		location => 'libxml2/',
		pattern  => qr/^libxml2-([\d\.]+)\.tar\.gz$/,
	},
	alien_build_commands => [
		'%c --prefix=%s --without-python --enable-shared --enable-static',
		'make',
	],
	alien_isolate_dynamic => 1,
	sign => 1,
	meta_merge => {
		resources => {
			repository => 'git://github.com/tobyink/p5-alien-libxml.git',
			homepage   => 'https://metacpan.org/release/Alien-LibXML',
			bugtracker => 'http://rt.cpan.org/Dist/Display.html?Queue=Alien-LibXML',
		},
		x_contributors => [
			'Graham Ollis (PLICEASE) <plicease@cpan.org>',
		],
	},
);
$builder->create_build_script;

