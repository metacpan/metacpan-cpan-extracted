use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Acme::MyFirstModule::WWILLIS',
    license             => 'perl',
    dist_author         => 'Will Willis <wwillis@cpan.org>',
    dist_version_from   => 'lib/Acme/MyFirstModule/WWILLIS.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Acme-MyFirstModule-WWILLIS-*' ],
);

$builder->create_build_script();
