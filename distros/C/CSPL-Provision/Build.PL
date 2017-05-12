use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CSPL::Provision',
    license             => 'artistic2',
    dist_author         => 'Kaoru Oshita <kaoru.oshita@gmail.com>',
    dist_version_from   => 'lib/CSPL/Provision.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'CSPL-Provision-*' ],
);

$builder->create_build_script();
