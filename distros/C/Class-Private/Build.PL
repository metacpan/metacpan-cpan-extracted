use 5.010000;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Class::Private',
    license             => 'perl',
    dist_author         => 'Leon Timmermans <leont@cpan.org>',
    dist_version_from   => 'lib/Class/Private.pm',
	configure_requires  => {
		'Module::Build' => 0,
	},
	build_requires => {
		'Module::Build' => 0,
		'Test::More'    => 0,
		'Test::NoWarnings' => 0,
	},
	requires => {
		perl            => 5.010000,
	},
    add_to_cleanup      => [ 'Class-Private-*' ],
    create_makefile_pl  => 'small',
	meta_merge => {
		resources       => {
			bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-Private',
			repository  => 'http://github.com/Leont/class-private/tree',
		},
		keywords       => [ 'OO', 'privacy' ],
	},
	sign               => 1,
);

$builder->create_build_script();
