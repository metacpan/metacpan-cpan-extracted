use strict;
use warnings;
use Module::Build;

eval { require ExtUtils::PkgConfig; }
    or die "Could not load ExtUtils::PkgConfig; please make sure it is intalled\n";

my %pkg_info = ExtUtils::PkgConfig->find('libofa');

my $builder = Module::Build->new(
    create_readme               => 1,
    create_makefile_pl          => 'small',
    #create_makefile_pl          => 'traditional',
    module_name                 => 'Audio::Ofa',
    dist_author                 => 'Christoph Bussenius <pepe@cpan.org>',
    dist_abstract               => 'Bindings for libofa',
    dist_version_from           => 'lib/Audio/Ofa.pm',
    configure_requires          => {
        'ExtUtils::PkgConfig' => 0,
        'Module::Build' => 0, # important if we are run through the generated
                              # Makefile.PL
    },
    build_requires              => {
        'Test::More'    => 0,
        'Compress::Zlib' => 0,
        'ExtUtils::PkgConfig' => 0,
        'Module::Build' => 0,
    },
    no_index => {
        directory => 'example',
    },
    extra_compiler_flags        => [
                  '-Wall',
                  (map /\S+/g, grep defined, $ENV{EXTRACFLAGS}),
                  split ' ', $pkg_info{cflags},
    ],
    extra_linker_flags          => [
                  split ' ', $pkg_info{libs},
    ],
    license => 'gpl',
);



$builder->create_build_script();
