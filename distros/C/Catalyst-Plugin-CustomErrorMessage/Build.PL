use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Catalyst::Plugin::CustomErrorMessage',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jozef@kutej.net>',
    dist_version_from   => 'lib/Catalyst/Plugin/CustomErrorMessage.pm',
    requires => {
		'Class::Data::Inheritable' => 0,
		'HTML::Entities'           => 0,
		'URI::Escape'              => 0,
		'MRO::Compat'              => 0,
    },
    build_requires => {
        'Test::More'               => 0,
        'Class::Accessor::Fast'    => 0,
		'Carp::Clan'               => 0,    	
    },
    add_to_cleanup      => [ 'Catalyst-Plugin-CustomErrorMessage-*' ],
    create_makefile_pl  => 'traditional',
    sign                => 1,
    create_readme       => 1,
);

$builder->create_build_script();
