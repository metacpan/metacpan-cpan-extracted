use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Catalyst::Model::EmailStore',
    license             => 'perl',
    dist_author         => 'Sebastian Willert <willert@cpan.org>',
    dist_version_from   => 'lib/Catalyst/Model/EmailStore.pm',
    dist_abstract       => 'Email::Store model for Catalyst',
    build_requires => {
        'Test::More' => 0,
		  'Email::Store' => '0.24',
        'Catalyst'     => '5.55'
    },
    add_to_cleanup      => [ 'Catalyst-Model-EmailStore-*' ],
);

$builder->create_build_script();
