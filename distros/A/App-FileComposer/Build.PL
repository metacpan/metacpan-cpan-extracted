use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name         => 'App::FileComposer',
    license             => 'gpl_2',
    dist_author         => q{Ariel Vieira <ariel.vieira@yandex.com>},
    script_files        => qw[ bin/mkscript ],
    dist_version_from   => 'lib/App/FileComposer.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0',
    },
    requires => {
        'Moose'  => '2.2203',
        'Term::ANSIColor' => '5.01',
        'Carp'  => '1.52'
   },
    add_to_cleanup     => [ 'App-FileComposer-*' ],
);

$builder->create_build_script();
