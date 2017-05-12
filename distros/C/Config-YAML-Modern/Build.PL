use 5.008;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Config::YAML::Modern',
    license             => 'perl',
    dist_author         => q{Meettya <meettya@cpan.org>},
    dist_version_from   => 'lib/Config/YAML/Modern.pm',
    configure_requires 	=> { 'Module::Build' => 0.38 },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.008,
        'Carp' => 1.20,
        'File::Basename' => 2.82,
        'File::Spec' => 3.33,
        'File::Glob' => 1.12,
        'YAML::Any' => 0.72,
        'Data::Diver' => 1.0101,
        'Hash::Merge' => 0.12
    },
    add_to_cleanup      => [ 'Config-YAML-Modern-*' ],
    create_makefile_pl => 'traditional',
    meta_merge     => {
    	resources => {
      	repository  => 'https://github.com/Meettya/Config-YAML-Modern/'
    }
  },
);

$builder->create_build_script();
