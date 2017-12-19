[% module = module || 'module' -%]
[% file     = module -%]
[% IF file.match('::') -%]
[%     file = file.replace('::', '/') -%]
[% END -%]
[% file = file _ '.pm' -%]
[% package  = module -%]
[% IF package.match('::') -%]
[%     package = package.replace('::', '-') -%]
[% END -%]
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name       => '[% module %]',
	license           => 'perl',
	dist_author       => '[% contact.fullname %] <[% contact.email %]>',
	dist_version_from => 'lib/[% file %]',
	requires          => {
		'perl'             => 5.008,
	},
	build_requires => {
		'Test::More'     => 0,
		'Test::Warnings' => 0,
	},
	add_to_cleanup     => [ '[% package %]-*' ],
	create_license     => 1,
	meta_merge => {
		resources => {
			repository => 'git://github.com/ivanwills/[% package %].git',
			bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=[% module %]',
		},
	},
);

$builder->create_build_script();
