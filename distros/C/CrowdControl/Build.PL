use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CrowdControl',
    license             => 'perl',
    dist_author         => 'Kirrily "Skud" Robert <skud@cpan.org>',
    dist_version_from   => 'lib/CrowdControl.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'CrowdControl-*' ],
);

$builder->create_build_script();
