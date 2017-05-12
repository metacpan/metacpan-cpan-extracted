use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Dancer::Plugin::FormattedOutput',
    license             => 'perl',
    dist_author         => q{Alex Kalderimis <alex kalderimis at gmail dot com>},
    dist_version_from   => 'lib/Dancer/Plugin/FormattedOutput.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Dancer-Plugin-FormattedOutput-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
