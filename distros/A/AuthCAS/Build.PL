use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'AuthCAS',
    license             => 'perl',
    dist_author         => 'Olivier Salaun <os AT cru.fr>',
    dist_version_from   => 'lib/AuthCAS.pm',
    create_license    => 1,
    requires => {
        'IO::Socket::SSL' => 0,
    	'LWP::UserAgent' => 0,
    },
    build_requires    => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'AuthCAS-*' ],
    meta_add           => {
        resources => {
            homepage => 'https://sourcesup.renater.fr/projects/perlcas/',
            repository => 'https://subversion.renater.fr/perlcas/',
        }
    }
);

$builder->create_build_script();
