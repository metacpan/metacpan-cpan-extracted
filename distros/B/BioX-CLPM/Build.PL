use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'BioX::CLPM',
    license             => 'perl',
    dist_author         => 'Nathan Crabtree <crabtree@cpan.org>',
    dist_version_from   => 'lib/BioX/CLPM.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'BioX-CLPM-*' ],
);

$builder->create_build_script();
