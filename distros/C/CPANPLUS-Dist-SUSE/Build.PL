use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'CPANPLUS::Dist::SUSE',
    license           => 'perl',
    dist_author       => q{Qindel Formacion y Servicios, SL <Nito@Qindel.ES>},
    dist_version_from => 'lib/CPANPLUS/Dist/SUSE.pm',
    build_requires    => { 'Test::More' => 0, },
    requires          => {
        'CPANPLUS::Dist::RPM' => 0,
        'English'             => 0,
        'CPANPLUS::Error'     => 0,
        'IPC::Cmd'            => 0,
        'Path::Class'         => 0,
        'SUPER'               => 0,
    },
    add_to_cleanup     => ['CPANPLUS-Dist-SUSE-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
