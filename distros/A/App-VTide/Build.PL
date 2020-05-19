use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'App::VTide',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/App/VTide.pm',
    requires          => {
        'perl'                => '5.014',
        'Array::Utils'        => 0,
        'File::chdir'         => '0.1008',
        'File::Touch'         => '0.11',
        'Getopt::Alt'         => '0.5.2',
        'Hash::Merge::Simple' => '0.051',
        'IO::Prompt'          => 0,
        'List::MoreUtils'     => '0.413',
        'List::Util'          => '1.41',
        'Module::Pluggable'   => 0,
        'Moo'                 => '2.000001',
        'Path::Tiny'          => '0.068',
        'Scalar::Util'        => '1.41',
        'Tie::Handle::Scalar' => 0,
        'version'             => '0.9909',
        'YAML::Syck'          => '1.29',
    },
    recommends => {
        'Term::Title' => 0.
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::More'     => '0.88',
        'Test::Warnings' => '0.026',
    },
    add_to_cleanup     => [ 'App-VTide-*' ],
    create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/ivanwills/App-VTide.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=App::VTide',
        },
    },
);

$builder->create_build_script();
