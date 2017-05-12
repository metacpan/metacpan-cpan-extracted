use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Catalyst::Plugin::Setenv',
    license             => 'perl',
    dist_author         => 'Jonathan Rockway <jrockway@cpan.org>',
    dist_version_from   => 'lib/Catalyst/Plugin/Setenv.pm',
    requires => {
		 'Catalyst::Runtime' => '5.7', # duh
		 'NEXT' => 0, # duh
		},
    build_requires => {
		       'Test::More' => 0,
		       'FindBin' => 0,
    },
    add_to_cleanup      => [ 'Catalyst-Plugin-Setenv-*' ],
);

$builder->create_build_script();
