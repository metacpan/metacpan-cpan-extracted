use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::EUMM::Migrate',
    license             => 'gpl3',
    dist_author         => q{Alexandr Ciornii <alexchorny@gmail.com>},
    dist_version_from   => 'lib/App/EUMM/Migrate.pm',
    requires => {
        'File::Slurp' => 0,
        #'Text::FindIndent' => 0,
        'Github::Fork::Parent' => 1.0,
        'Data::Dumper' => 0,
        'Perl::Meta' => 0,
        'perl' => 5.006,
    },
    build_requires => {
        'Test::More' => 0,
    },
    script_files => [
        'eumm-migrate.pl',
    ],
    meta_merge => {
        resources => {
            repository => 'https://github.com/chorny/EUMM-migrate',
            bugtracker => 'https://github.com/chorny/EUMM-migrate/issues',
        },
        keywords => [
            'development','upgrade','EU::MM','Makefile.PL','Module::Build',
        ],
    },
    add_to_cleanup      => [ 'App-EUMM-Migrate-*' ],
    create_makefile_pl => 'traditional',
    auto_configure_requires => 0,
);

$builder->create_build_script();
