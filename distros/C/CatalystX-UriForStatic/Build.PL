use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CatalystX::UriForStatic',
    license             => 'perl',
    dist_author         => q{Matthias Dietrich <perl@rainboxx.de>},
    dist_version_from   => 'lib/CatalystX/UriForStatic.pm',
    build_requires => {
        'Test::More' => 0,
        'Moose' => 0,
        'Catalyst' => '5.80029',
    },
    add_to_cleanup      => [ 'CatalystX-UriForStatic-*' ],
    create_makefile_pl => 'traditional',
    meta_merge => {
        resources => {
            repository  => 'http://github.com/rainboxx/CatalystX-UriForStatic/'
        }
    },
);

$builder->create_build_script();
