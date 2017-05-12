use strict;
use warnings;
use Module::Build;
use 5.010;

my $builder = Module::Build->new(
    module_name       => 'App-Fotagger',
    license           => 'perl',
    dist_author       => 'Thomas Klausner',
    dist_version_from => 'lib/App/Fotagger.pm',
    requires => {
        'perl'             => '5.010',
        'Moose'         => '0.79',
        'SDL'           => '1.20',
        'Image::ExifTool' => '7.67',
        'File::Find::Rule' => '0',
        'DateTime' => '0',
        'Imager'=>'0',
        'File::Find::Rule'=>0,
    },

    build_requires    => {
        'Test::More'       => 0,
    },
    add_to_cleanup     => ['App-Fotagger-*'],
    create_makefile_pl => 'passthrough',
    recursive_test_files => 1,
    meta_merge     => {
        resources => {
            bugtracker =>
                'http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Fotagger',
            repository => 'http://github.com/domm/fotagger',
        }
    },


);

$builder->create_build_script();
