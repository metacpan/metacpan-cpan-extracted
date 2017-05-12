use strict;
use warnings;
use Module::Build;

use Config;

if($Config{osname} =~ m/win/i) {
    die 'No support for OS',$/;
}

my $builder = Module::Build->new(
    meta_merge => {
        resources => {
            repository => {
                url => 'https://github.com/duncs/perl-app-bk.git',
                web => 'http://github.com/duncs/perl-app-bk',
                type => 'git',
            },
            bugtracker => {
                web => 'https://github.com/duncs/perl-app-bk/issues',
            },
            homepage   => 'https://github.com/duncs/perl-app-bk',
        },
    },
    module_name       => 'App::bk',
    license           => 'perl',
    dist_author       => q{Duncan Ferguson <duncan_j_ferguson@yahoo.co.uk>},
    dist_version_from => 'lib/App/bk.pm',
    dist_abstract     => 'A pre-edit file backup program',
    requires          => {
        'FindBin'        => 0,
        'File::Basename' => 0,
        'Getopt::Long'   => 0,
        'Pod::Usage'     => 0,
        'English'        => 0,
        'POSIX'          => 0,
        'File::Copy'     => 0,
        'File::Which'    => 0,
    },
    build_requires => {
        'CPAN::Meta::Spec' => 2.133380,
        'Module::Build'  => 0.42,
        'FindBin'        => 0,
        'Test::More'     => 0.94,
        'File::Basename' => 0,
        'Getopt::Long'   => 0,
        'Pod::Usage'     => 0,
        'English'        => 0,
        'POSIX'          => 0,
        'File::Copy'     => 0,
        'File::Which'    => 0,
        'Test::Trap'     => 0,
    },
    configure_requires => { 'Module::Build' => 0.42 },
    add_to_cleanup     => ['App-bk-*', 't/file[12].txt.*'],
    create_makefile_pl => 'traditional',
    script_files       => 'bin',
);

$builder->create_build_script();
